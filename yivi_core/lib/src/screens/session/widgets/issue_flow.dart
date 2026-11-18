import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../data/irma_repository.dart";
import "../../../models/credential.dart";
import "../../../models/credential_store.dart";
import "../../../models/session_state.dart";
import "../../../providers/contact_issuance_provider.dart";
import "../../../providers/credential_store_provider.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../providers/session_flow_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/after_frame.dart";
import "../../../util/i18n.dart";
import "../../../util/navigation.dart";
import "../../../widgets/flight/yivi_flight.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/glass/sheet_actions.dart";
import "../../../widgets/glass/sheet_layout.dart";
import "../../../widgets/yivi_spinner.dart";
import "../../add_data/add_data_details_content.dart";
import "../../embedded_issuance_flows/documents/document_flow.dart";
import "../../embedded_issuance_flows/documents/document_sheet_step.dart";
import "../../embedded_issuance_flows/widgets/contact_sheet_step.dart";
import "../../error/session_error_screen.dart";
import "../../error/tx_code_lockout_screen.dart";
import "../issue_flow/issue_flow_controller.dart";
import "../models/disclosure_view_model.dart";
import "../models/issuance_view_model.dart";
import "../models/session_view.dart";
import "../models/technical_details.dart";
import "issuance_permission.dart";
import "issuance_success_screen.dart";
import "issue_island.dart";
import "issue_sheet_progress.dart";
import "issue_website_step.dart";
import "openid4vci_preauth_txcode_screen.dart";
import "received_card_tile.dart";
import "requestor_card.dart";
import "requestor_trust_sheet.dart";
import "session_pin_entry_screen.dart";
import "technical_details_sheet.dart";

/// Sends the user to the issuer of a credential type: its website, or the
/// app's own flow for the types Yivi issues itself (e-mail, phone,
/// documents). A provider, so tests can see where the sheet sends the user.
final issuerOpenerProvider =
    Provider<
      Future<void> Function(
        BuildContext context,
        CredentialDescriptor descriptor,
        WidgetRef ref,
      )
    >(
      (ref) =>
          (context, d, widgetRef) => ref
              .read(irmaRepositoryProvider)
              .openIssueURL(context, d.credentialId, d.issueURL, widgetRef),
    );

/// [name] as it reads inside a sentence in the app's language
/// ([inSentence]).
String inSentenceAt(BuildContext context, String name) =>
    inSentence(name, language: context.lang);

/// Adding a card inside a sheet, in three steps under an
/// [IssueSheetProgress]: 1 its details (as on the add-data page), 2 proving
/// it (Yivi's own e-mail, phone or document steps, or the issuer's website,
/// from which the user comes back to the sheet), and 3 the issuance itself
/// ("Do you want to add this data?", the PIN if irmago asks, then
/// "Success"). Once adding has started, closing the sheet asks first.
///
/// Where the flow is, and what it does, is the [IssueFlowController] of
/// this sheet; this draws its pages and does what needs the sheet's
/// context (the flights, asking before stopping, the pages over the sheet).
///
/// The sheet's state mixes this in and puts [issueFlowPages] after its own
/// root page in a [GlassSheetPages], with [issueBack] as its back. It says
/// what differs per sheet by overriding the members below: the Change sheet
/// of a request adds a card for that request, Add data adds one on its own.
mixin IssueFlow<W extends ConsumerStatefulWidget> on ConsumerState<W>
    implements IssueFlowHost {
  // ---------- what the sheet supplies ----------

  /// The request the card is added for, or null when there is none.
  SessionState? get issueRequest;

  /// The session of [issueRequest], or null for a sheet that adds a card on
  /// its own (Add data): a session that starts while another request waits
  /// is not for this sheet.
  int? get underlyingSessionId;

  /// The tag of the progress while [d] is added.
  IssueSheetSubject issueSubject(CredentialDescriptor d);

  /// The text of "Stop adding {name}?".
  String issueStopText();

  /// Called on "Add", before the issuer is contacted.
  void beforeIssueAdd(CredentialDescriptor d) {}

  /// The way on from "Success" (in the bar, or at the bottom of a phone
  /// held upright), for the added [cards].
  SheetAction issueSuccessAction(List<Credential> cards);

  /// Another choice on "Success" ("Add more", "Later"), as a link under
  /// what is now in the app; none by default.
  IssueSuccessLink? issueSuccessLink(List<Credential> cards) => null;

  /// The text under "Success", for the added [cards].
  String issueSuccessText(List<Credential> cards);

  /// Where a session the sheet can't show is pushed full screen: the
  /// sheet's own context, unless the sheet lives where the router isn't
  /// (the lock screen's scanner sheet).
  BuildContext get issueRouteContext => context;

  /// A standalone issuance ([issueTakeSession]) ended without being added:
  /// declined, dismissed, or an error was closed.
  void issueSessionEnded() {}

  /// The e-mail step links the address to the keyshare server: its flow is
  /// [ContactFlow.linkEmail].
  bool get issueLinking => false;

  /// The issuance in the sheet succeeded ([issueAdded] is set, so closing
  /// does not dismiss it). True: the host took over; "Success" is not
  /// shown.
  bool issueSucceeded(List<Credential> cards) => false;

  /// There is something else to choose than the card being added: the
  /// website step then offers "Choose something else".
  bool get issueHasOtherChoices => false;

  // ---------- the flow ----------

  /// Where step 1's picture is: a card lifted from the share screen lands
  /// there.
  final issueHeroKey = GlobalKey(debugLabel: "issue_hero");

  /// The big heading of each page (by page): the bar's title shows once it
  /// has scrolled under the bar.
  final _titleKeys = <String, GlobalKey>{};

  GlobalKey _titleKey(String page) =>
      _titleKeys[page] ??= GlobalKey(debugLabel: "issue_title_$page");

  CredentialDescriptor? _startWith;

  /// This sheet's flow; made on first use, after [issueStartWith].
  late final IssueFlowConfig _config = IssueFlowConfig(
    host: this,
    requestId: underlyingSessionId,
    linking: issueLinking,
    start: _startWith,
  );

  /// Keeps the flow while this state lives; its build watches it.
  ProviderSubscription<IssueFlowState>? _flowSub;
  IssueFlowController? _controller;

  ProviderSubscription<IssueFlowState> get _sub {
    final sub = _flowSub;
    if (sub != null) return sub;
    final made = _flowSub = ref.listenManual(
      issueFlowProvider(_config),
      (_, _) {},
    );
    _controller = ref.read(issueFlowProvider(_config).notifier);
    return made;
  }

  IssueFlowState get _s => _sub.read();

  IssueFlowController get _flow {
    _sub;
    return _controller!;
  }

  IrmaRepository get _repo => ref.read(irmaRepositoryProvider);

  /// Opens the sheet straight on [d]'s details; call from the host's
  /// initState. Null: the sheet opens on its root page. [prove]: on step 2
  /// at once, as if "Add" had been tapped on the details.
  void issueStartWith(CredentialDescriptor? d, {bool prove = false}) {
    assert(_flowSub == null, "issueStartWith before the flow is used");
    _startWith = d;
    if (prove && d != null) afterFrame(() => _add(d));
  }

  /// The type the user is adding; null while on the sheet's root page.
  CredentialDescriptor? get issueAdding => _s.adding;

  /// The cards of a finished issuance, kept for "Success" (the session state
  /// moves on once the request picks them up).
  List<Credential>? get issueAdded => _s.added;

  /// Where each of [issueAdded] is drawn on "Success", to fly from.
  List<GlobalKey> get issueAddedKeys {
    final added = issueAdded;
    if (added != null && !identical(added, _keysFor)) {
      _keysFor = added;
      _addedKeys = [
        for (final (i, _) in added.indexed)
          GlobalKey(debugLabel: "sheet_added_$i"),
      ];
    }
    return _addedKeys;
  }

  List<Credential>? _keysFor;
  List<GlobalKey> _addedKeys = const [];

  @override
  void dispose() {
    _controller?.detach();
    super.dispose();
  }

  // ---------- what the flow asks of the sheet ----------

  @override
  bool onSucceeded(List<Credential> cards) => mounted && issueSucceeded(cards);

  @override
  void onSessionEnded() {
    if (mounted) issueSessionEnded();
  }

  @override
  Future<void> showOverSheet(SessionView view) async {
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) => switch (view) {
          SessionFailed(:final error, :final state) => SessionErrorScreen(
            // The error as Go sent it (it may have none); else why the
            // state could not be shown.
            error: state?.status == SessionStatus.error ? state!.error : error,
            onTapClose: () => Navigator.of(context).pop(),
          ),
          _ => TxCodeLockoutScreen(
            onTapClose: () => Navigator.of(context).pop(),
          ),
        },
      ),
    );
  }

  @override
  void handOver(int sessionId) {
    if (!mounted) return;
    issueRouteContext.pushSessionScreen(
      SessionRouteParams(
        sessionId: sessionId,
        hasUnderlyingSession: issueRequest != null,
      ),
    );
  }

  /// "Choose something else" on the website step: adding stops (after
  /// asking, once the website was opened) and the sheet's root page shows.
  Future<void> _issueChooseOther() async {
    if (_s.opened && !await _issueConfirmStop(closing: false)) return;
    if (!mounted) return;
    _flow.chooseOther();
  }

  /// The sheet is closing: it keeps the pages it had ([_shownPages]) until it
  /// has gone, instead of going back to an earlier one on the way out.
  bool _closing = false;
  List<Widget>? _shownPages;

  /// Closes the sheet on the page it is on; what is left running ends once
  /// it has gone.
  void issueClose() {
    _startClosing();
    Navigator.of(context).pop();
  }

  void _startClosing() {
    _closing = true;
    _flow.startClosing();
  }

  /// Adding has started: closing asks first. Not on the details page, where
  /// nothing has happened yet.
  bool get _issueStarted => _s.started;

  /// Takes the next session that starts into this sheet (an issuance
  /// scanned on the lock screen): its offer, the PIN if irmago asks and
  /// "Success" show here, without a type picked first.
  void issueTakeSession() => _flow.takeSession();

  /// An issuance is in this sheet: started, or finished on "Success".
  bool get issueHasSession => _s.hasSession;

  /// No longer takes the next session ([issueTakeSession]).
  void issueReleaseSession() => _flow.releaseSession();

  /// Opens the details of [d] (step 1).
  void issueOpen(CredentialDescriptor d) => _flow.open(d);

  /// Back from the details to the root page, leaving nothing behind. When
  /// the details are the sheet's first page, the sheet closes instead.
  void _issueLeave() {
    if (_s.direct) {
      // Asked already where it had to be (or nothing was started yet).
      issueClose();
      return;
    }
    _flow.leave();
  }

  /// After a finished issuance, on to the sheet's root page (Add more),
  /// also when the sheet opened straight on the card.
  void issueShowRoot() => _flow.showRoot();

  /// Done with a finished issuance: the flow starts over on the root page
  /// (a sheet that opened straight on the card keeps it as its first page
  /// while it closes).
  void issueReset() => _flow.reset();

  /// How adding [d] goes: Yivi's own steps or the issuer's website.
  IssuePlan _planOf(CredentialDescriptor d) =>
      issuePlanOf(d, _repo.embeddedFlowOf(d.credentialId));

  /// How many steps adding [d] takes, for the progress ([IssuePlan.total]);
  /// a document's own count once its flow has started.
  int _stepsOf(CredentialDescriptor d) => _planOf(d).total(
    documentTotal: switch (_s.document) {
      final type? => ref.watch(documentFlowProvider(type)).total,
      null => null,
    },
  );

  /// "Add" on the details: Yivi's own e-mail, phone or document steps in the
  /// sheet, or the issuer's website with the sheet waiting for what comes
  /// back. Either way the issuance then shows in the sheet.
  void _add(CredentialDescriptor d) {
    beforeIssueAdd(d);
    _flow.add(d);
  }

  /// "Open website" on the website page: the sheet waits for what comes
  /// back from the issuer.
  Future<void> _openWebsite(CredentialDescriptor d) async {
    _flow.websiteOpened();
    await ref.read(issuerOpenerProvider)(context, d, ref);
  }

  /// Back from the website page to the details. Once the website was
  /// opened, adding has started: it asks first, and stopping ends the wait.
  Future<void> _leaveWebsite() async {
    if (_s.opened) {
      final stop = await _issueConfirmStop(closing: false);
      // Stopped, adding has ended and the details show; not asked (nothing
      // was started), only the page goes.
      if (!stop || !mounted || _s.stack.lastOrNull is! WebsiteStep) return;
    }
    _flow.back();
  }

  /// "Stop adding {name}?" before a started adding is left. When the sheet
  /// is [closing] it stays on its page while it goes, and the adding ends
  /// once it has gone.
  Future<bool> _issueConfirmStop({bool closing = true}) async {
    final d = issueAdding;
    if (d == null || !_issueStarted) return true;
    final stop =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => GlassDialog(
            cardKey: const Key("sheet_stop_dialog"),
            title: context.tr("share.sheet.stop_title", {
              "name": inSentenceAt(context, d.name),
            }),
            message: issueStopText(),
            actions: [
              PillButton(
                key: const Key("sheet_stop_confirm"),
                label: context.tr("share.sheet.stop_confirm"),
                style: PillStyle.dangerFilled,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
              PillButton(
                key: const Key("sheet_stop_keep"),
                label: context.tr("share.sheet.keep_going"),
                style: PillStyle.text,
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
            ],
          ),
        ) ??
        false;
    if (stop && closing) {
      _startClosing();
    } else if (stop) {
      _flow.stopAdding();
    }
    return stop;
  }

  /// The sheet: its own [root] page (under the key [rootKey]) and then the
  /// flow's pages, asking before it closes once adding has started. Opened
  /// on one card, the flow's first page takes the root's place.
  Widget issueSheet({
    required String rootKey,
    required Widget Function() root,
    required VoidCallback onBack,
    double? rootShift,
  }) {
    // Popped, however (its close button, a drag, a tap outside, Done): the
    // sheet keeps its pages while it goes.
    final route = ModalRoute.of(context);
    if (route != null && !route.isActive && !_closing) _startClosing();
    return GlassSheetConfirmDismiss(
      ask: _issueStarted,
      confirm: _issueConfirmStop,
      // On a phone held upright the close button stays at the top right on
      // every page of adding. Sideways the way on is in the bar, in the
      // close button's place, with the progress after "For …".
      child: SheetKeepsClose(
        child: Builder(
          builder: (_) => IssueIslandScope(
            open: _flow.openIsland,
            isOpen: _islandOpen,
            child: Stack(
              // The pages get the sheet's own constraints: a short page
              // still makes a low sheet.
              fit: StackFit.passthrough,
              children: [
                GlassSheetPages(
                  onBack: onBack,
                  rootShift: rootShift,
                  pages: _closing && _shownPages != null
                      ? _shownPages!
                      : _shownPages = [
                          if (!_s.direct || issueAdding == null)
                            KeyedSubtree(key: ValueKey(rootKey), child: root()),
                          ...issueFlowPages(),
                        ],
                ),
                if (_islandOpen)
                  Positioned.fill(
                    child: IssueIsland(
                      requestor: issueRequest!.requestor,
                      signing: issueRequest!.type == SessionType.signature,
                      onClose: _flow.closeIsland,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The island shows while adding a card for a request, not over the
  /// sheet's root page or once the card is in.
  bool get _islandOpen =>
      _s.island &&
      issueRequest != null &&
      issueAdding != null &&
      issueAdded == null &&
      !_closing;

  /// Back in the sheet: one step back, or from the details to the root page
  /// ([IssueFlowController.back]). The issuer's pages take their logo back
  /// with them, an opened website asks first, and the details of a sheet
  /// opened on them close it.
  void issueBack() {
    final s = _s;
    switch (s.stack.lastOrNull) {
      // Swiped back, the page is out of the sheet already: no logo flies
      // back from there.
      case DetailsIssuerStep():
        final issuer = s.adding?.issuer;
        if (issuer != null && !_pageOut(_detailsLogoTo)) {
          _closeDetailsIssuer(issuer);
          return;
        }
      case IssuerStep(technical: false):
        final issuer = s.lastOffer?.offeredCredentials?.firstOrNull?.issuer;
        if (issuer != null && !_pageOut(_issuerLogoTo)) {
          _closeIssuerPage(issuer);
          return;
        }
      case WebsiteStep(opened: true):
        _leaveWebsite();
        return;
      case DetailsStep() when s.direct:
        _issueLeave();
        return;
      case _:
    }
    _flow.back();
  }

  // ---------- the issuance in the sheet ----------

  /// Follows the flow, and the issuance in it; call from the sheet's build.
  void issueListen() {
    _sub;
    ref.watch(issueFlowProvider(_config));
  }

  // ---------- the pages ----------

  /// The flow's pages, to follow the sheet's root page in its
  /// [GlassSheetPages]; none while on the root page.
  List<Widget> issueFlowPages() {
    final s = _s;
    final adding = s.adding;
    if (adding == null) return _standalonePages();
    final nested = s.sessionId;
    final subject = issueSubject(adding);
    final total = _stepsOf(adding);
    return [
      KeyedSubtree(
        key: ValueKey(("add", adding.credentialId)),
        child: _buildDetails(adding, subject, total),
      ),
      // The issuer's page, from the ⓘ on the details' issuer card.
      if (s.detailsIssuer)
        KeyedSubtree(
          key: ValueKey(("details_issuer", adding.credentialId)),
          child: RequestorTrustSheet(
            key: const Key("details_issuer_page"),
            requestor: adding.issuer,
            issuer: true,
            logoKey: _detailsLogoTo,
            onBack: () => _closeDetailsIssuer(adding.issuer),
          ),
        ),
      // Step 2 for a card from a website: where you go, and the way there.
      if (s.website)
        KeyedSubtree(
          key: ValueKey(("web", adding.credentialId)),
          child: IssueWebsiteStep(
            title: adding.name,
            host: hostOf(adding.issueURL) ?? adding.issuer.name,
            issuer: adding.issuer.name,
            opened: s.opened,
            onOpen: () => _openWebsite(adding),
            onBack: _leaveWebsite,
            bottom: IssueSheetProgress(step: 2, total: total),
            titleWidget: IssueRequestorPill.maybe(subject),
            onOther: issueHasOtherChoices ? _issueChooseOther : null,
          ),
        ),
      if (s.contact case final flow?) ...[
        KeyedSubtree(
          key: ValueKey(("prove", flow)),
          child: ContactSheetStep(
            flow: flow,
            subject: subject,
            total: total,
            onBack: _flow.leaveContact,
          ),
        ),
        // Once the code is sent, its page slides in over the address.
        if (ContactSheetStep.atCode(ref, flow))
          KeyedSubtree(
            key: ValueKey(("code", flow)),
            child: ContactSheetStep(
              flow: flow,
              subject: subject,
              total: total,
              code: true,
              onBack: _flow.leaveContact,
            ),
          ),
      ],
      if (s.document case final document?)
        KeyedSubtree(
          key: ValueKey(("document", document)),
          // A sheet page itself: its bar and progress stay while the
          // document's screens change below them.
          child: DocumentSheetStep(
            type: document,
            subject: subject,
            onBack: _flow.leaveDocument,
          ),
        ),
      if (nested != null || s.added != null)
        KeyedSubtree(
          key: ValueKey(("issue", nested)),
          child: _buildIssuance(nested, subject, total),
        ),
      ..._issuerPages(nested),
      ..._issuanceTail(nested, subject, total),
    ];
  }

  /// The issuer's logo on the question page, and on the issuer's page: it
  /// flies between them as the page slides in and out.
  final _issuerLogoFrom = GlobalKey(debugLabel: "issuer_logo_from");

  /// The issuer's card on the permission: once it has gone up under the
  /// bar, the issuer sticks in a row under the bar.
  final _issuerCardKey = GlobalKey(debugLabel: "issuer_card");
  final _issuerLogoTo = GlobalKey(debugLabel: "issuer_logo_to");

  /// The issuer's page slides in over the question; its logo grows from the
  /// question's into its own (360 ms, with the slide).
  void _openIssuerPage(TrustedParty issuer) {
    YiviFlight.hide([_issuerLogoTo]);
    _flow.openIssuer();
    afterFrame(() {
      YiviFlight.show([_issuerLogoTo]);
      _flyIssuerLogo(issuer, from: _issuerLogoFrom, to: _issuerLogoTo);
    });
  }

  /// The issuer's page with the logo at [logoKey] is out of the sheet, to
  /// its right (swiped back).
  bool _pageOut(GlobalKey logoKey) {
    final logo = logoKey.currentContext?.findRenderObject();
    final sheet = context.findRenderObject();
    if (logo is! RenderBox || sheet is! RenderBox) return true;
    if (!logo.hasSize || !sheet.hasSize) return true;
    final right = sheet.localToGlobal(Offset(sheet.size.width, 0)).dx;
    return logo.localToGlobal(Offset.zero).dx >= right - 1;
  }

  /// Back to the question: the logo shrinks back into the question's.
  void _closeIssuerPage(TrustedParty issuer) {
    _flyIssuerLogo(issuer, from: _issuerLogoTo, to: _issuerLogoFrom);
    _flow.closeIssuer();
  }

  /// The issuer's logo on the details' issuer card, and on the issuer's page
  /// over the details: their own pair, as the details stay under the
  /// question (which has the other pair).
  final _detailsLogoFrom = GlobalKey(debugLabel: "details_issuer_logo_from");
  final _detailsLogoTo = GlobalKey(debugLabel: "details_issuer_logo_to");

  /// The issuer's page slides in over the details, its logo growing from
  /// the issuer card's.
  void _openDetailsIssuer(TrustedParty issuer) {
    YiviFlight.hide([_detailsLogoTo]);
    _flow.openDetailsIssuer();
    afterFrame(() {
      YiviFlight.show([_detailsLogoTo]);
      _flyIssuerLogo(issuer, from: _detailsLogoFrom, to: _detailsLogoTo);
    });
  }

  /// Back to the details: the logo shrinks back into the issuer card's.
  void _closeDetailsIssuer(TrustedParty issuer) {
    _flyIssuerLogo(issuer, from: _detailsLogoTo, to: _detailsLogoFrom);
    _flow.closeDetailsIssuer();
  }

  void _flyIssuerLogo(
    TrustedParty issuer, {
    required GlobalKey from,
    required GlobalKey to,
  }) {
    final style = RequestorTrustStyle.of(context, issuer);
    YiviFlight.start(
      context,
      from: from,
      to: YiviFlight.boxOf(to),
      keys: const [FlightKey(0, FlightKey.start), FlightKey(1, FlightKey.end)],
      duration: GlassSheetPages.slideDuration,
      curve: YiviMotion.ease,
      hide: [from, to],
      copy: (context, frame) => RequestorLogo(
        requestor: issuer,
        style: style,
        size: frame.size.width,
      ),
    );
  }

  /// The issuer's details, from the trust label on the question, as pages
  /// of the sheet (back returns to the question), and their technical
  /// details under them.
  List<Widget> _issuerPages(int? nested) {
    final s = _s;
    final offer = s.lastOffer;
    final cards = offer?.offeredCredentials;
    if (s.issuerDepth == 0 || offer == null || cards == null || cards.isEmpty) {
      return const [];
    }
    final issuer = cards.first.issuer;
    return [
      KeyedSubtree(
        key: ValueKey(("issuer", nested)),
        child: RequestorTrustSheet(
          key: const Key("issuer_trust_page"),
          requestor: issuer,
          issuer: true,
          logoKey: _issuerLogoTo,
          onBack: () => _closeIssuerPage(issuer),
          onTechnicalDetails: () => _flow.openIssuer(technical: true),
        ),
      ),
      if (s.issuerDepth >= 2)
        KeyedSubtree(
          key: ValueKey(("issuer_tech", nested)),
          child: TechnicalDetailsSheet(
            key: const Key("issuer_technical_details"),
            groups: issuanceTechnicalDetailsOf(offer, cards, context.tr),
            onBack: () => _flow.closeIssuer(technical: true),
          ),
        ),
    ];
  }

  /// The pages after the issuance's offer: the PIN while irmago asks for it
  /// (it stays under "Success" once shown), and "Success", a page of its
  /// own, coming in forward over the offer (or the PIN).
  List<Widget> _issuanceTail(
    int? nested,
    IssueSheetSubject? subject,
    int total,
  ) => [
    if (nested != null && _s.pinShown)
      KeyedSubtree(
        key: ValueKey(("pin", nested)),
        child: _NestedPin(
          sessionId: nested,
          subject: subject,
          total: total,
          onCancel: _flow.dismissSession,
        ),
      ),
    if (_s.added case final added?)
      KeyedSubtree(
        key: ValueKey(("done", nested)),
        child: _buildSuccess(added, subject, total),
      ),
  ];

  /// A session taken without a type picked first ([issueTakeSession]): its
  /// issuance and, while irmago asks, the PIN. No progress: it has no steps
  /// before it.
  List<Widget> _standalonePages() {
    final s = _s;
    final nested = s.sessionId;
    if (!s.standalone || (nested == null && s.added == null)) {
      return const [];
    }
    final state = nested == null
        ? null
        : ref.watch(sessionStateProvider(nested)).value;
    final requestor = state?.requestor;
    final subject = requestor == null
        ? null
        : IssueSheetSubject.request(requestor);
    return [
      KeyedSubtree(
        key: ValueKey(("issue", nested)),
        child: _buildIssuance(nested, subject, 0),
      ),
      ..._issuerPages(nested),
      ..._issuanceTail(nested, subject, 0),
    ];
  }

  /// Step 1: what the card is, as on the add-data page. It stays under the
  /// pages of step 2, which go back to it.
  Widget _buildDetails(
    CredentialDescriptor d,
    IssueSheetSubject subject,
    int total,
  ) {
    final faq = _faqFor(d.credentialId);
    // One way on: dragging the sheet down and back are the way out.
    final action = SheetAction(
      key: const Key("sheet_go_button"),
      label: context.tr("data.add.details.get_button"),
      onTap: () => _add(d),
    );
    final howIntro = switch (_planOf(d).howIntroKey) {
      final key? => context.tr(key),
      null => null,
    };
    Widget part(AddDataDetailsPart part) => AddDataDetailsContent(
      credential: d,
      faq: faq,
      heroKey: issueHeroKey,
      titleKey: _titleKey("details"),
      howIntro: howIntro,
      part: part,
      onIssuer: () => _openDetailsIssuer(d.issuer),
      issuerLogoKey: _detailsLogoFrom,
    );
    // A phone held sideways: the card, its name and the intro at the left,
    // what you get at the right; the way on is in the bar.
    final split = useSheetColumns(context)
        ? SheetSplit(
            start: [part(AddDataDetailsPart.card)],
            end: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: YiviSpace.x12,
              children: [part(AddDataDetailsPart.rest)],
            ),
          )
        : null;
    return split != null
        ? GlassSheetPage.split(
            // "Add {name}" names the page; the card's name is its heading, and
            // the bar shows the title only once that has scrolled away.
            title: SheetTitle(
              context.tr("data.add.details.title_add", {"name": d.name}),
              widget: IssueRequestorPill.maybe(subject),
              centred: true,
              reveal: SheetTitleReveal.under(_titleKey("details")),
            ),
            // The sheet's first page has no back: its close button is the way out,
            // where back is on the pages after it. Otherwise left by back or by
            // dragging its header down.
            exits: SheetExits(
              onBack: _s.direct ? null : _issueLeave,
              close: _s.direct ? SheetClose.start : SheetClose.none,
            ),
            action: action,
            bottomInBar: true,
            bottom: IssueSheetProgress(step: 1, total: total),
            child: split,
          )
        : GlassSheetPage.scroll(
            // "Add {name}" names the page; the card's name is its heading, and
            // the bar shows the title only once that has scrolled away.
            title: SheetTitle(
              context.tr("data.add.details.title_add", {"name": d.name}),
              widget: IssueRequestorPill.maybe(subject),
              centred: true,
              reveal: SheetTitleReveal.under(_titleKey("details")),
            ),
            // The sheet's first page has no back: its close button is the way out,
            // where back is on the pages after it. Otherwise left by back or by
            // dragging its header down.
            exits: SheetExits(
              onBack: _s.direct ? null : _issueLeave,
              close: _s.direct ? SheetClose.start : SheetClose.none,
            ),
            padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
            action: action,
            bottom: IssueSheetProgress(step: 1, total: total),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: YiviSpace.x16,
              children: [part(AddDataDetailsPart.all)],
            ),
          );
  }

  Faq? _faqFor(String credentialId) {
    final store = ref.watch(groupedCredentialStoreProvider).value;
    for (final group in store ?? const <CredentialStoreCategory>[]) {
      for (final item in group.items) {
        if (item.credential.credentialId == credentialId) return item.faq;
      }
    }
    return null;
  }

  /// Step 3: the issuance that came back, then "Success".
  Widget _buildIssuance(int? nestedId, IssueSheetSubject? subject, int total) {
    final view = nestedId == null
        ? null
        : ref.watch(sessionFlowProvider(nestedId));
    if (_openIdStepOf(view) case final step? when nestedId != null) {
      return _buildOpenIdStep(step, nestedId);
    }
    final awaiting =
        nestedId != null &&
        ref.watch(sessionAwaitingInteractionProvider(nestedId));
    // After "Add", and under "Success" (sliding away as it comes in), the
    // offer as it was: the session has moved on by then.
    final s = _s;
    final current = view is SessionOffer ? view.state : null;
    final offer =
        current ?? (s.added != null || s.granted ? s.lastOffer : null);
    final cards = offer?.offeredCredentials ?? const <Credential>[];

    // Inside a request, a card whose value is not what the request needs
    // does not count: trying again comes first, adding it anyway second.
    // Nobody vouches for the issuer: adding becomes "Add anyway", neutral,
    // with the reason above it and a red wash at the top, as sharing with a
    // requestor nobody vouches for.
    final state = issuanceOfferOf(
      cards,
      forRequest: issueRequest,
      retryOnMismatch: true,
    );
    final grant = offer == null || nestedId == null ? null : _flow.grant;
    final issuer = state.issuer;
    final risky = state.risky;
    final action = switch (state.primary) {
      IssuancePrimary.retry || IssuancePrimary.dontReplace => SheetAction(
        key: const Key("sheet_issue_retry"),
        label: context.tr(
          state.primary == IssuancePrimary.dontReplace
              ? "share.offer.dont_replace"
              : "share.offer.retry",
        ),
        onTap: state.primary == IssuancePrimary.dontReplace
            ? issueClose
            : _flow.retry,
      ),
      IssuancePrimary.add || IssuancePrimary.addAnyway => SheetAction(
        key: const Key("sheet_issue_add"),
        label: risky
            ? context.tr("issuance.question.add_anyway")
            : issuanceAddLabel(context, cards.length),
        neutral: risky,
        // Under way once tapped, until "Success" comes in.
        busy: awaiting,
        onTap: grant,
      ),
    };
    final anyway = switch (state.link) {
      final link? => Center(
        child: TextLink(
          key: const Key("sheet_issue_add"),
          label: context.tr(switch (link) {
            IssuanceLink.replaceAnyway => "share.offer.replace_anyway",
            IssuanceLink.addAnyway => "share.offer.add_anyway",
          }),
          onPressed: awaiting ? null : grant,
        ),
      ),
      null => null,
    };
    // Above the button: why it says "anyway" for an issuer nobody vouches
    // for (no progress then: it is the last step anyway); else the progress.
    final bottom = risky
        ? IssuanceRiskyReason(
            issuer: issuer!,
            textAlign: useSheetColumns(context)
                ? TextAlign.start
                : TextAlign.center,
          )
        : IssueSheetProgress.lastStep(total);
    final content = offer == null ? null : state;
    final question = issuer == null
        ? null
        : issuanceHeading(
            context,
            issuer: issuer,
            count: cards.length,
            titleKey: _titleKey("issuance"),
            logoKey: _issuerLogoFrom,
            cardKey: _issuerCardKey,
            onTrust: () => _openIssuerPage(issuer),
          );
    final loading = _loading();
    // The cards: their values in tiles, the mismatch note above them.
    List<Widget> cardsAndValues(IssuanceOfferState content) => [
      const YouGetLabel(),
      ?IssuanceMismatchNote.maybe(content),
      ...receivedCardTiles(context, content),
      ?anyway,
    ];
    final sideways = useSheetColumns(context);
    final page = sideways
        ? GlassSheetPage.split(
            // The question is the page's heading; the bar names the page once
            // that has scrolled away. The issuer sticks under the bar once their
            // card has (the "For" pill stays in the bar).
            title: SheetTitle(
              context.tr("issuance.title"),
              widget: IssueRequestorPill.maybe(subject),
              centred: true,
              reveal: SheetTitleReveal.under(_titleKey("issuance")),
            ),
            // Back declines this issuance: on the details again, to try again.
            exits: SheetExits(onBack: issueBack),
            action: action,
            // The progress in the bar sideways; the reason stays with the button.
            bottomInBar: !risky,
            bottom: bottom,
            child: sideways
                // A phone held sideways: the issuer and the question at the left
                // with the button under them; the cards at the right.
                ? SheetSplit(
                    key: content == null ? null : const Key("sheet_issuance"),
                    start: [?question],
                    end: content == null
                        ? loading
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: YiviSpace.x8,
                            children: cardsAndValues(content),
                          ),
                  )
                : content == null || question == null
                ? loading
                : KeyedSubtree(
                    key: const Key("sheet_issuance"),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [question, ...cardsAndValues(content)],
                    ),
                  ),
          )
        : GlassSheetPage.scroll(
            // The question is the page's heading; the bar names the page once
            // that has scrolled away. The issuer sticks under the bar once their
            // card has (the "For" pill stays in the bar).
            title: SheetTitle(
              context.tr("issuance.title"),
              widget: IssueRequestorPill.maybe(subject),
              centred: true,
              reveal: SheetTitleReveal.under(_titleKey("issuance")),
            ),
            // Back declines this issuance: on the details again, to try again.
            exits: SheetExits(onBack: issueBack),
            padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
            action: action,
            bottom: bottom,
            underBar: issuer == null || sideways
                ? null
                : (
                    row: RequestorCompactBar(
                      requestor: issuer,
                      subtitle: cards.length > 1
                          ? context.tr("issuance.bar_subtitle.many", {
                              "count": "${cards.length}",
                            })
                          : context.tr("issuance.bar_subtitle.one"),
                    ),
                    after: _issuerCardKey,
                  ),
            child: sideways
                // A phone held sideways: the issuer and the question at the left
                // with the button under them; the cards at the right.
                ? SheetSplit(
                    key: content == null ? null : const Key("sheet_issuance"),
                    start: [?question],
                    end: content == null
                        ? loading
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: YiviSpace.x8,
                            children: cardsAndValues(content),
                          ),
                  )
                : content == null || question == null
                ? loading
                : KeyedSubtree(
                    key: const Key("sheet_issuance"),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [question, ...cardsAndValues(content)],
                    ),
                  ),
          );
    return IssuanceTrustWash(on: risky, child: page);
  }

  /// A page still waiting for the issuance's next state.
  Widget _loading() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 80),
    child: Center(child: YiviSpinner()),
  );

  /// OpenID4VCI's own step before the offer in [view], if it is one: a
  /// transaction code, the issuer's website for the authorization code, or
  /// the wait while a pre-authorized code without a transaction code is
  /// granted. While a tap waits for Go's answer the step stays.
  SessionView? _openIdStepOf(SessionView? view) {
    final step = switch (view) {
      SessionWaiting(:final state?) => sessionViewOf(state, awaiting: false),
      _ => view,
    };
    return switch (step) {
      SessionTxCode() || SessionAuthCode() => step,
      SessionWaiting(:final state?)
          when state.status == SessionStatus.requestPreAuthorizedCode =>
        step,
      _ => null,
    };
  }

  /// OpenID4VCI's transaction code or authorization-code step ([step], from
  /// [_openIdStepOf]), as a page. Back declines the issuance.
  Widget _buildOpenIdStep(SessionView step, int sessionId) {
    final flow = ref.read(sessionFlowProvider(sessionId).notifier);
    switch (step) {
      case SessionTxCode(:final state, :final parameters):
        return OpenID4VCIPreAuthTxCodeScreen(
          inSheet: true,
          sessionId: sessionId,
          issuedCredentials: state.offeredCredentialTypes ?? const [],
          transactionCodeParameters: parameters,
          onSubmit: flow.grantPreAuthorizedCode,
          onDismiss: _flow.dismissSession,
        );
      case SessionAuthCode(:final state, :final url):
        // The issuer's login in the browser: the website page of adding a
        // card, as for a card from a website.
        return IssueWebsiteStep(
          key: const Key("sheet_openid4vci_authcode"),
          title: context.tr("issuance.authorization_code.pending.title"),
          host: hostOf(url) ?? state.requestor.name,
          issuer: state.requestor.name,
          opened: _s.authOpened.contains(sessionId),
          onOpen: () => _flow.openAuthorization(sessionId, url),
          onBack: _flow.dismissSession,
        );
      default:
        // Granted at once (by the session's flow); the next state follows.
        return GlassSheetPage.scroll(
          title: SheetTitle(context.tr("issuance.title")),
          // Left by dragging its header down: no close button.
          exits: SheetExits(
            onBack: _flow.dismissSession,
            close: SheetClose.none,
          ),
          child: _loading(),
        );
    }
  }

  Widget _buildSuccess(
    List<Credential> cards,
    IssueSheetSubject? subject,
    int total,
  ) {
    final palette = YiviPalette.of(context);
    final action = issueSuccessAction(cards);
    final link = issueSuccessLink(cards);
    final linkText = link == null
        ? null
        : TextLink(key: link.key, label: link.label, onPressed: link.onTap);
    final linkButton = linkText == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: YiviSpace.x8),
            // Under the words they go with: centred upright, at the start
            // of the column sideways.
            child: useSheetColumns(context)
                ? Align(
                    alignment: AlignmentDirectional.centerStart,
                    // Its words flush with the text above (the link pads
                    // its tap area by 8).
                    child: Transform.translate(
                      offset: Offset(
                        Directionality.of(context) == TextDirection.rtl
                            ? 8
                            : -8,
                        0,
                      ),
                      child: linkText,
                    ),
                  )
                : Center(child: linkText),
          );
    // "Success" is the page's heading; the bar names it only once that has
    // scrolled away. Done: no progress; the way on is the way out.
    final received = Center(
      child: SizedBox(
        // The card at about four fifths of the page's width (the success
        // picture is the card minus 48 of room for its check).
        width: _receivedWidth + 48,
        child: IssuanceReceived(cards: cards, cardKeys: issueAddedKeys),
      ),
    );
    final heading = Semantics(
      header: true,
      child: Text(
        context.tr("issuance.success_feedback.header"),
        key: _titleKey("done"),
        style: palette.titleStep.copyWith(color: palette.text),
      ),
    );
    final text = Text(
      issueSuccessText(cards),
      key: const Key("sheet_added_text"),
      style: palette.body(16).copyWith(height: 24 / 16),
    );
    // A phone held sideways: "Success", the words and the way on at the
    // left; the card with its check at the right.
    if (useSheetColumns(context)) {
      return GlassSheetPage.split(
        title: SheetTitle(
          context.tr("issuance.success_feedback.header"),
          widget: IssueRequestorPill.maybe(subject),
          centred: true,
          reveal: SheetTitleReveal.under(_titleKey("done")),
        ),
        exits: SheetExits(close: SheetClose.none),
        action: action,
        child: SheetSplit(
          start: [heading, text, ?linkButton],
          end: Column(
            key: const Key("sheet_added_values"),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [if (cards.isNotEmpty) received],
          ),
        ),
      );
    }
    return GlassSheetPage.scroll(
      title: SheetTitle(
        context.tr("issuance.success_feedback.header"),
        widget: IssueRequestorPill.maybe(subject),
        centred: true,
        reveal: SheetTitleReveal.under(_titleKey("done")),
      ),
      exits: SheetExits(close: SheetClose.none),
      padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
      action: action,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: YiviSpace.x16,
        children: [
          if (cards.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 90), child: received),
          DefaultTextStyle.merge(
            textAlign: TextAlign.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: YiviSpace.x16,
              children: [
                Center(child: heading),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: YiviSpace.x24,
                  ),
                  child: text,
                ),
              ],
            ),
          ),
          ?linkButton,
        ],
      ),
    );
  }

  /// The added card's width on "Success".
  static const double _receivedWidth = 298;
}

/// An [IssueFlow] that adds a card on its own, not for a request (the Add
/// data sheet, the scanner over the lock screen): no session under it, the
/// card as the subject, and "Done" on "Success" calls [issueDone].
mixin StandaloneIssueFlow<W extends ConsumerStatefulWidget> on IssueFlow<W> {
  /// "Done" on "Success".
  void issueDone();

  @override
  int? get underlyingSessionId => null;

  @override
  SessionState? get issueRequest => null;

  @override
  IssueSheetSubject issueSubject(CredentialDescriptor d) =>
      const IssueSheetSubject.none();

  @override
  String issueStopText() => context.tr("data.add.stop_text");

  @override
  String issueSuccessText(List<Credential> cards) => context.tr(
    cards.length > 1
        ? "issuance.success_feedback.added_many"
        : "issuance.success_feedback.added_one",
    {"name": cards.firstOrNull?.name ?? "", "count": "${cards.length}"},
  );

  @override
  SheetAction issueSuccessAction(List<Credential> cards) => SheetAction(
    key: const Key("sheet_done"),
    label: context.tr("ui.done"),
    onTap: issueDone,
  );
}

/// A choice on "Success" besides its way on, as a link
/// ([IssueFlow.issueSuccessLink]).
typedef IssueSuccessLink = ({String label, VoidCallback onTap, Key key});

/// The PIN for the issuance in the sheet, as a page of the sheet: the PIN
/// pad without the logo, under the sheet's bar and the progress.
class _NestedPin extends StatelessWidget {
  final int sessionId;
  final IssueSheetSubject? subject;

  /// The flow's number of steps; the PIN is part of the last (adding it).
  /// 0: an issuance without steps before it, and no progress.
  final int total;
  final VoidCallback onCancel;

  const _NestedPin({
    required this.sessionId,
    required this.subject,
    required this.total,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // The pad fills the page and scales itself to it; it does not scroll.
    // It keeps clear of the home indicator itself (YiviPinScreen), so the
    // link under the keypad sits as low as on the full-screen PIN.
    return GlassSheetPage.fill(
      title: SheetTitle(
        context.tr("issuance.title"),
        widget: IssueRequestorPill.maybe(subject),
        centred: true,
      ),
      // Left by dragging its header down: no close button.
      exits: SheetExits(onBack: onCancel, close: SheetClose.none),
      padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
      child: SessionPinPage(
        key: const Key("sheet_pin"),
        sessionId: sessionId,
        inSheet: true,
        onCancel: onCancel,
      ),
    );
  }
}
