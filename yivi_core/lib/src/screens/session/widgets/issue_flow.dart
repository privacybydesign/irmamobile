import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart" show DocumentType;

import "../../../data/irma_repository.dart";
import "../../../models/requestor_trust.dart";
import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../providers/email_issuance_provider.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../providers/nested_issuance_host_provider.dart";
import "../../../providers/preferences_provider.dart";
import "../../../providers/schemaless_credential_store_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../providers/sms_issuance_provider.dart";
import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../util/navigation.dart";
import "../../../widgets/flight/yivi_flight.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/glass/sheet_actions.dart";
import "../../../widgets/glass/sheet_layout.dart";
import "../../../widgets/loading_indicator.dart";
import "../../add_data/add_data_details_content.dart";
import "../../embedded_issuance_flows/documents/document_sheet_step.dart";
import "../../embedded_issuance_flows/widgets/contact_sheet_step.dart";
import "../../error/session_error_screen.dart";
import "../models/disclosure_view_model.dart";
import "../models/technical_details.dart";
import "issuance_permission.dart";
import "issuance_success_screen.dart";
import "issue_island.dart";
import "issue_sheet_progress.dart";
import "issue_website_step.dart";
import "openid4vci_preauth_txcode_screen.dart";
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
/// The sheet's state mixes this in and puts [issueFlowPages] after its own
/// root page in a [GlassSheetPages], with [issueBack] as its back. It says
/// what differs per sheet by overriding the members below: the Change sheet
/// of a request adds a card for that request, Add data adds one on its own.
mixin IssueFlow<W extends ConsumerStatefulWidget> on ConsumerState<W>
    implements NestedIssuanceHost {
  // ---------- what the sheet supplies ----------

  /// The request the card is added for, or null when there is none.
  SessionState? get issueRequest;

  /// The tag of the progress while [d] is added.
  IssueSheetSubject issueSubject(CredentialDescriptor d);

  /// The text of "Stop adding {name}?".
  String issueStopText();

  /// Called on "Add", before the issuer is contacted.
  void beforeIssueAdd(CredentialDescriptor d) {}

  /// The way on from "Success" (in the bar, or at the bottom of a phone
  /// held upright), for the added [cards].
  SheetAction issueSuccessAction(List<schemaless.Credential> cards);

  /// Another choice on "Success" ("Add more", "Later"), as a link under
  /// what is now in the app; none by default.
  IssueSuccessLink? issueSuccessLink(List<schemaless.Credential> cards) => null;

  /// The text under "Success", for the added [cards].
  String issueSuccessText(List<schemaless.Credential> cards);

  /// Where a session the sheet can't show is pushed full screen: the
  /// sheet's own context, unless the sheet lives where the router isn't
  /// (the lock screen's scanner sheet).
  BuildContext get issueRouteContext => context;

  /// A standalone issuance ([issueTakeSession]) ended without being added:
  /// declined, dismissed, or an error was closed.
  void issueSessionEnded() {}

  // ---------- the flow's state ----------

  /// Where step 1's picture is: a card lifted from the share screen lands
  /// there.
  final issueHeroKey = GlobalKey(debugLabel: "issue_hero");

  /// The big heading of each page (by page): the bar's title shows once it
  /// has scrolled under the bar.
  final _titleKeys = <String, GlobalKey>{};

  GlobalKey _titleKey(String page) =>
      _titleKeys[page] ??= GlobalKey(debugLabel: "issue_title_$page");

  /// The type the user is adding; null while on the sheet's root page.
  CredentialDescriptor? issueAdding;

  /// The sheet opened straight on [issueAdding] (a card to get again, or
  /// the only one a request can use): its details are the sheet's first
  /// page, with nothing to go back to. Leaving them closes the sheet.
  bool _direct = false;

  /// Opens the sheet straight on [d]'s details; call from the host's
  /// initState. Null: the sheet opens on its root page.
  void issueStartWith(CredentialDescriptor? d) {
    issueAdding = d;
    _direct = d != null;
  }

  /// The issuer's details over the question (1), and their technical
  /// details over those (2); 0: none.
  int _issuerDepth = 0;

  /// The island over the sheet ([IssueIsland]): why the card is added,
  /// during a request. Only opened from the pill in the bar.
  bool _island = false;

  void _closeIsland() {
    if (_island) setState(() => _island = false);
  }

  /// There is something else to choose than the card being added: the
  /// website step then offers "Choose something else".
  bool get issueHasOtherChoices => false;

  /// "Choose something else" on the website step: adding stops (after
  /// asking, once the website was opened) and the sheet's root page shows.
  Future<void> _issueChooseOther() async {
    if (_opened && !await _issueConfirmStop(closing: false)) return;
    if (!mounted) return;
    _stopAdding();
    setState(() {
      issueAdding = null;
      _direct = false;
    });
  }

  /// The sheet takes the next session that starts, without a type picked
  /// first ([issueTakeSession]): only its issuance pages show.
  bool _standalone = false;

  /// OpenID4VCI sessions whose pre-authorized code was granted already.
  final _vciGranted = <int>{};

  /// The issuer's website was opened for [issueAdding].
  bool _opened = false;

  /// The page that sends the user to the issuer's website is shown (step
  /// 2): "Add" on the details of a card from a website.
  bool _website = false;

  /// OpenID4VCI sessions whose login page in the browser was opened.
  final _vciOpened = <int>{};

  /// Yivi's own e-mail or phone step for [issueAdding] is shown (step 2).
  ContactKind? _contact;

  /// The document screens for [issueAdding] are shown (step 2).
  DocumentType? _document;

  /// The issuer asked for a face check while adding the document: a step
  /// more in the progress.
  bool _faceCheck = false;

  /// Counts the times adding the document went back to its chip screen, to
  /// read it again ([DocumentSheetStep.readAgain]).
  int _readAgain = 0;

  /// The issuance that came back from the issuer, shown in the sheet.
  int? _nestedId;

  /// The cards of a finished issuance, kept for "Success" (the session state
  /// moves on once the request picks them up).
  List<schemaless.Credential>? issueAdded;

  /// Where each of [issueAdded] is drawn on "Success", to fly from.
  List<GlobalKey> issueAddedKeys = const [];

  /// A full-screen page shown over the sheet for the issuance (an error).
  bool _overSheet = false;

  /// irmago asks for the PIN for the issuance in the sheet.
  bool _pin = false;

  /// The PIN page was shown for the issuance: it stays under "Success", so
  /// "Success" comes in over it (forward) instead of the PIN going away.
  bool _pinShown = false;

  /// The last offer shown, for the offer page while "Success" covers it,
  /// and while irmago adds the card after "Add" ([_granted]).
  SessionState? _lastOffer;

  /// "Add" was tapped on the offer: it stays as it was (no loading in its
  /// place for the moment before "Success" or the PIN), and a second tap
  /// does nothing.
  bool _granted = false;

  // The repository only once something is added, kept for dispose (where
  // ref is unsafe). The host notifier up front for the same reason.
  IrmaRepository? _repoRead;
  IrmaRepository get _repo {
    final read = _repoRead;
    if (read != null) return read;
    final repo = ref.read(irmaRepositoryProvider);
    _repoRead = repo;
    return repo;
  }

  late final NestedIssuanceHostNotifier _hosts;

  @override
  void initState() {
    super.initState();
    _hosts = ref.read(nestedIssuanceHostProvider.notifier);
  }

  @override
  void attach(int sessionId) {
    if (!mounted) return;
    final previous = _nestedId;
    if (previous != null && previous != sessionId) _dismissNested(previous);
    setState(() {
      _nestedId = sessionId;
      issueAdded = null;
      _pinShown = false;
      _lastOffer = null;
      _granted = false;
    });
  }

  @override
  void dispose() {
    final nested = _nestedId;
    final repo = _repoRead;
    final added = issueAdded != null;
    if (_closing) {
      // Closed while adding: end what it left running once the sheet has
      // gone (providers can't change while the tree is being torn down).
      final hosts = _hosts;
      final opened = _opened;
      final contact = _contact != null;
      final container = _container;
      Future.microtask(() {
        hosts.unregister(this);
        if (added) return;
        if (nested != null) repo?.dismissSession(nested);
        if (opened) repo?.clearInAppLaunches();
        if (contact && container != null) {
          container
            ..invalidate(emailIssuanceProvider)
            ..invalidate(smsIssuanceProvider);
        }
      });
    } else {
      _hosts.unregister(this);
      // A nested id means the repository was read (the website was opened).
      if (nested != null && !added) repo?.dismissSession(nested);
    }
    super.dispose();
  }

  /// The sheet is closing: it keeps the pages it had ([_shownPages]) until it
  /// has gone, instead of going back to an earlier one on the way out.
  bool _closing = false;
  List<Widget>? _shownPages;
  ProviderContainer? _container;

  /// Closes the sheet on the page it is on; what is left running ends once
  /// it has gone (see [dispose]).
  void issueClose() {
    _startClosing();
    Navigator.of(context).pop();
  }

  /// What [dispose] needs to end the adding, read now: ref and the context
  /// are unsafe there.
  void _startClosing() {
    _closing = true;
    if (!mounted) return;
    _container = ProviderScope.containerOf(context, listen: false);
    if (_nestedId != null || _opened) _repo;
  }

  /// Adding has started: closing asks first. Not on the details page, where
  /// nothing has happened yet.
  bool get _issueStarted =>
      issueAdding != null && issueAdded == null && !_onDetails;

  /// The details of the type being added are the page on top: no step
  /// after them is open and no issuance is running.
  bool get _onDetails =>
      !_website &&
      _contact == null &&
      _document == null &&
      _nestedId == null &&
      !_pin;

  /// Takes the next session that starts into this sheet (an issuance
  /// scanned on the lock screen): its offer, the PIN if irmago asks and
  /// "Success" show here, without a type picked first.
  void issueTakeSession() {
    _standalone = true;
    _hosts.register(this);
  }

  /// An issuance is in this sheet: started, or finished on "Success".
  bool get issueHasSession => _nestedId != null || issueAdded != null;

  /// No longer takes the next session ([issueTakeSession]).
  void issueReleaseSession() {
    _hosts.unregister(this);
    if (_nestedId == null) _standalone = false;
  }

  /// Opens the details of [d] (step 1).
  void issueOpen(CredentialDescriptor d) => setState(() {
    issueAdding = d;
    _direct = false;
    _opened = false;
    _website = false;
  });

  /// Back from the details to the root page, leaving nothing behind. When
  /// the details are the sheet's first page ([_direct]), the sheet
  /// closes instead.
  void _issueLeave() {
    if (_direct) {
      // Asked already where it had to be (or nothing was started yet).
      issueClose();
      return;
    }
    _stopAdding();
    setState(() => issueAdding = null);
  }

  /// After a finished issuance, on to the sheet's root page (Add more),
  /// also when the sheet opened straight on the card.
  void issueShowRoot() {
    issueReset();
    _direct = false;
  }

  /// Done with a finished issuance: the flow starts over on the root page
  /// (a sheet that opened straight on the card keeps it as its first page
  /// while it closes).
  void issueReset() {
    issueAdded = null;
    issueAdding = null;
    _forgetSession();
    _clearSteps();
  }

  /// The issuance in the sheet is gone: no session, no PIN page kept under
  /// "Success", no offer kept.
  void _forgetSession() {
    _issuerDepth = 0;
    _nestedId = null;
    _pinShown = false;
    _lastOffer = null;
    _granted = false;
  }

  /// Back from the document screens to the details.
  void _leaveDocument() => setState(() {
    _document = null;
    _faceCheck = false;
  });

  /// None of the steps that prove the card is under way: no website opened,
  /// no e-mail, phone or document step.
  void _clearSteps() {
    _opened = false;
    _website = false;
    _contact = null;
    _document = null;
    _faceCheck = false;
  }

  /// Ends what adding left running: the issuance, the waiting host, the
  /// launch record.
  void _stopAdding() {
    final nested = _nestedId;
    if (nested != null && issueAdded == null) _dismissNested(nested);
    _hosts.unregister(this);
    if (_opened) _repo.clearInAppLaunches();
    if (_contact != null) {
      ref
        ..invalidate(emailIssuanceProvider)
        ..invalidate(smsIssuanceProvider);
    }
    _forgetSession();
    issueAdded = null;
    _clearSteps();
  }

  /// Adding a document goes back to its chip screen, which starts over: the
  /// issuer asks for a face check again if it wants one.
  void _backToChip() {
    if (_document == null) return;
    _readAgain++;
    _faceCheck = false;
  }

  void _dismissNested(int sessionId) => _repo.dismissSession(sessionId);

  /// How many steps adding [d] takes, for the progress: the details, the
  /// steps that prove it, and adding it. A website is one step (3 in all);
  /// an e-mail address or phone number two, the address and the code (4); a
  /// document three, how to hold it, scanning or typing it in, and the chip
  /// (5), and a fourth once the issuer asks for a face check (6).
  int _stepsOf(CredentialDescriptor d) =>
      switch (_repo.embeddedFlowOf(d.credentialId)) {
        EmbeddedFlow.email || EmbeddedFlow.phone => 4,
        EmbeddedFlow.document when documentTypeOf(d.credentialId) != null =>
          _faceCheck ? 6 : 5,
        _ => 3,
      };

  /// "Add" on the details: Yivi's own e-mail, phone or document steps in the
  /// sheet, or the issuer's website with the sheet waiting for what comes
  /// back. Either way the issuance then shows in the sheet.
  void _add(CredentialDescriptor d) {
    beforeIssueAdd(d);
    final flow = _repo.embeddedFlowOf(d.credentialId);
    if (flow == EmbeddedFlow.email || flow == EmbeddedFlow.phone) {
      if (!_repo.prepareEmbeddedFlow(d.credentialId, d.issueURL, ref)) return;
      _hosts.register(this);
      setState(
        () => _contact = flow == EmbeddedFlow.email
            ? ContactKind.email
            : ContactKind.phone,
      );
      return;
    }
    final document = flow == EmbeddedFlow.document
        ? documentTypeOf(d.credentialId)
        : null;
    if (document != null) {
      if (!_repo.prepareEmbeddedFlow(d.credentialId, d.issueURL, ref)) return;
      _hosts.register(this);
      setState(() {
        _document = document;
        _faceCheck = false;
      });
      return;
    }
    // The issuer's website (every document Yivi issues itself has a
    // DocumentType): first the page that says so.
    setState(() => _website = true);
  }

  /// "Open website" on the website page: the sheet waits for what comes
  /// back from the issuer.
  Future<void> _openWebsite(CredentialDescriptor d) async {
    _hosts.register(this);
    setState(() => _opened = true);
    await ref.read(issuerOpenerProvider)(context, d, ref);
  }

  /// Back from the website page to the details. Once the website was
  /// opened, adding has started: it asks first, and ends the wait.
  Future<void> _leaveWebsite() async {
    if (_opened && !await _issueConfirmStop(closing: false)) return;
    if (!mounted) return;
    if (_opened) {
      _repo.clearInAppLaunches();
      _hosts.unregister(this);
    }
    setState(() {
      _website = false;
      _opened = false;
    });
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
      _stopAdding();
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
            open: () => setState(() => _island = true),
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
                          if (!_direct || issueAdding == null)
                            KeyedSubtree(key: ValueKey(rootKey), child: root()),
                          ...issueFlowPages(),
                        ],
                ),
                if (_islandOpen)
                  Positioned.fill(
                    child: IssueIsland(
                      requestor: issueRequest!.requestor,
                      signing: issueRequest!.type == SessionType.signature,
                      onClose: _closeIsland,
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
      _island &&
      issueRequest != null &&
      issueAdding != null &&
      issueAdded == null &&
      !_closing;

  /// Back in the sheet: one step back, or from the details to the root page.
  void issueBack() {
    // The issuer's details over the permission: back to what is under them.
    if (_issuerDepth == 2) {
      setState(() => _issuerDepth = 1);
      return;
    }
    if (_issuerDepth == 1) {
      final issuer = _lastOffer?.offeredCredentials?.firstOrNull?.issuer;
      // Swiped back, the page is out of the sheet already: no logo flies
      // back from there.
      if (issuer != null && !_issuerPageOut) {
        _closeIssuerPage(issuer);
      } else {
        setState(() => _issuerDepth = 0);
      }
      return;
    }
    final nested = _nestedId;
    if (_standalone && issueAdding == null && nested != null) {
      // Nothing to go back to: declines the issuance, which ends it
      // (issueSessionEnded once irmago says it is dismissed).
      _dismissNested(nested);
      return;
    }
    if (_pin && nested != null) {
      _dismissNested(nested);
    } else if (nested != null && issueAdded == null) {
      // A step back: a document's chip screen, to read it again; the
      // website or the address page, as they were.
      _dismissNested(nested);
      setState(() {
        _forgetSession();
        _backToChip();
      });
    } else if (_document != null) {
      _leaveDocument();
    } else if (_website) {
      _leaveWebsite();
    } else if (_contact case final kind?) {
      // From the code to the address; from the address to the details.
      if (ContactSheetStep.atCode(ref, kind, watch: false)) {
        ContactSheetStep.backToAddress(ref, kind);
      } else {
        setState(() => _contact = null);
      }
    } else {
      _issueLeave();
    }
  }

  // ---------- the issuance in the sheet ----------

  /// Follows the issuance in the sheet; call from the sheet's build.
  void issueListen() {
    final nested = _nestedId;
    if (nested == null) return;
    ref.listen(sessionStateProvider(nested), (prev, next) {
      if (next.value case final state?) _onNested(prev?.value, state);
    });
  }

  void _onNested(SessionState? previous, SessionState next) {
    final status = next.status;
    if (status == SessionStatus.success) {
      // Kept: the request picks the cards up and the state moves on.
      final cards = next.offeredCredentials ?? const [];
      _repo.clearInAppLaunches();
      _hosts.unregister(this);
      setState(() {
        _pin = false;
        issueAdded = cards;
        issueAddedKeys = [
          for (final (i, _) in cards.indexed)
            GlobalKey(debugLabel: "sheet_added_$i"),
        ];
      });
      return;
    }
    if (status == SessionStatus.dismissed) {
      if (_standalone && issueAdding == null) {
        _forgetSession();
        _pin = false;
        issueSessionEnded();
        return;
      }
      // Cancelled on the permission or the PIN: a step back, to try again.
      setState(() {
        _pin = false;
        _forgetSession();
        _backToChip();
      });
      return;
    }
    // The PIN is a page in the sheet, on top of the issuance, while irmago
    // asks for it.
    final pin = status == SessionStatus.requestPin;
    if (pin) _pinShown = true;
    if (pin != _pin) setState(() => _pin = pin);
    // OpenID4VCI without a transaction code: granted at once, as on the
    // session screen; the next state follows.
    if (status == SessionStatus.requestPreAuthorizedCode &&
        next.transactionCodeParameters == null &&
        _vciGranted.add(next.id)) {
      _grantPreAuthorizedCode(next.id, null);
    }
    if (status == previous?.status || _overSheet || pin) return;
    if (status == SessionStatus.error) {
      _showOverSheet(
        (context) => SessionErrorScreen(
          error: next.error,
          onTapClose: () => Navigator.of(context).pop(),
        ),
        then: () {
          if (!mounted) return;
          setState(() {
            _nestedId = null;
            _granted = false;
          });
          if (_standalone && issueAdding == null) issueSessionEnded();
        },
      );
    } else if (!_handledInSheet(next)) {
      // Anything else (a pairing code, an OpenID4VCI code, a request instead
      // of an issuance) takes the session screen, as without the sheet.
      final id = next.id;
      setState(() => _nestedId = null);
      issueRouteContext.pushSessionScreen(
        SessionRouteParams(
          sessionId: id,
          hasUnderlyingSession: issueRequest != null,
        ),
      );
      if (_standalone && issueAdding == null) issueSessionEnded();
    }
  }

  bool _handledInSheet(SessionState s) => _openIdStep(s) || _isOffer(s);

  /// "Do you want to add this data?": an issuance without anything to
  /// disclose first.
  bool _isOffer(SessionState s) =>
      s.status == SessionStatus.requestPermission &&
      s.type == SessionType.issuance &&
      s.offeredCredentials != null &&
      (s.disclosurePlan?.disclosureChoicesOverview?.isEmpty ?? true);

  /// OpenID4VCI's own steps before the offer: a transaction code, or the
  /// issuer's website for the authorization code. Shown in the sheet too.
  bool _openIdStep(SessionState s) =>
      s.status == SessionStatus.requestPreAuthorizedCode ||
      (s.status == SessionStatus.requestAuthorizationCode &&
          s.authorizationRequestUrl != null &&
          s.offeredCredentialTypes != null);

  void _grantPreAuthorizedCode(int sessionId, String? transactionCode) =>
      _repo.grantPreAuthorizedCode(sessionId, transactionCode);

  void _showOverSheet(WidgetBuilder builder, {VoidCallback? then}) {
    _overSheet = true;
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute<void>(builder: builder)).whenComplete(() {
      _overSheet = false;
      then?.call();
    });
  }

  void _grant(int sessionId) {
    if (_granted) return;
    _granted = true;
    _repo.grantSession(sessionId);
  }

  // ---------- the pages ----------

  /// The flow's pages, to follow the sheet's root page in its
  /// [GlassSheetPages]; none while on the root page.
  List<Widget> issueFlowPages() {
    final adding = issueAdding;
    if (adding == null) return _standalonePages();
    final nested = _nestedId;
    final subject = issueSubject(adding);
    final total = _stepsOf(adding);
    return [
      KeyedSubtree(
        key: ValueKey(("add", adding.credentialId)),
        child: _buildDetails(adding, subject, total),
      ),
      // Step 2 for a card from a website: where you go, and the way there.
      if (_website)
        KeyedSubtree(
          key: ValueKey(("web", adding.credentialId)),
          child: IssueWebsiteStep(
            title: adding.name,
            host: hostOf(adding.issueURL) ?? adding.issuer.name,
            issuer: adding.issuer.name,
            opened: _opened,
            onOpen: () => _openWebsite(adding),
            onBack: _leaveWebsite,
            bottom: IssueSheetProgress(step: 2, total: total),
            titleWidget: IssueRequestorPill.maybe(subject),
            onOther: issueHasOtherChoices ? _issueChooseOther : null,
          ),
        ),
      if (_contact case final kind?) ...[
        KeyedSubtree(
          key: ValueKey(("prove", kind)),
          child: ContactSheetStep(
            kind: kind,
            subject: subject,
            total: total,
            onBack: () => setState(() => _contact = null),
          ),
        ),
        // Once the code is sent, its page slides in over the address.
        if (ContactSheetStep.atCode(ref, kind))
          KeyedSubtree(
            key: ValueKey(("code", kind)),
            child: ContactSheetStep(
              kind: kind,
              subject: subject,
              total: total,
              code: true,
              onBack: () => setState(() => _contact = null),
            ),
          ),
      ],
      if (_document != null)
        KeyedSubtree(
          key: ValueKey(("document", _document)),
          // A sheet page itself: its bar and progress stay while the
          // document's screens change below them.
          child: DocumentSheetStep(
            type: _document!,
            subject: subject,
            total: total,
            onBack: _leaveDocument,
            onStopped: _issueLeave,
            onFaceCheck: () {
              if (!_faceCheck) setState(() => _faceCheck = true);
            },
            readAgain: _readAgain,
          ),
        ),
      if (nested != null || issueAdded != null)
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
  final _issuerLogoTo = GlobalKey(debugLabel: "issuer_logo_to");

  /// The issuer's page slides in over the question; its logo grows from the
  /// question's into its own (360 ms, with the slide).
  void _openIssuerPage(schemaless.TrustedParty issuer) {
    YiviFlight.hide([_issuerLogoTo]);
    setState(() => _issuerDepth = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      YiviFlight.show([_issuerLogoTo]);
      _flyIssuerLogo(issuer, from: _issuerLogoFrom, to: _issuerLogoTo);
    });
  }

  /// The issuer's page is out of the sheet, to its right (swiped back).
  bool get _issuerPageOut {
    final logo = _issuerLogoTo.currentContext?.findRenderObject();
    final sheet = context.findRenderObject();
    if (logo is! RenderBox || sheet is! RenderBox) return true;
    if (!logo.hasSize || !sheet.hasSize) return true;
    final right = sheet.localToGlobal(Offset(sheet.size.width, 0)).dx;
    return logo.localToGlobal(Offset.zero).dx >= right - 1;
  }

  /// Back to the question: the logo shrinks back into the question's.
  void _closeIssuerPage(schemaless.TrustedParty issuer) {
    _flyIssuerLogo(issuer, from: _issuerLogoTo, to: _issuerLogoFrom);
    setState(() => _issuerDepth = 0);
  }

  void _flyIssuerLogo(
    schemaless.TrustedParty issuer, {
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
    final offer = _lastOffer;
    final cards = offer?.offeredCredentials;
    if (_issuerDepth == 0 || offer == null || cards == null || cards.isEmpty) {
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
          onTechnicalDetails: () => setState(() => _issuerDepth = 2),
        ),
      ),
      if (_issuerDepth >= 2)
        KeyedSubtree(
          key: ValueKey(("issuer_tech", nested)),
          child: TechnicalDetailsSheet(
            key: const Key("issuer_technical_details"),
            groups: issuanceTechnicalDetailsOf(offer, cards, context.tr),
            onBack: () => setState(() => _issuerDepth = 1),
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
    if (nested != null && (_pin || (issueAdded != null && _pinShown)))
      KeyedSubtree(
        key: ValueKey(("pin", nested)),
        child: _NestedPin(
          sessionId: nested,
          subject: subject,
          total: total,
          onCancel: () => _dismissNested(nested),
        ),
      ),
    if (issueAdded case final added?)
      KeyedSubtree(
        key: ValueKey(("done", nested)),
        child: _buildSuccess(added, subject, total),
      ),
  ];

  /// A session taken without a type picked first ([issueTakeSession]): its
  /// issuance and, while irmago asks, the PIN. No progress: it has no steps
  /// before it.
  List<Widget> _standalonePages() {
    final nested = _nestedId;
    if (!_standalone || (nested == null && issueAdded == null)) {
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
    final howIntro = switch (_repo.embeddedFlowOf(d.credentialId)) {
      EmbeddedFlow.email => context.tr("data.add.details.how_email"),
      EmbeddedFlow.phone => context.tr("data.add.details.how_phone"),
      EmbeddedFlow.document when documentTypeOf(d.credentialId) != null =>
        context.tr("data.add.details.how_document"),
      _ => null,
    };
    Widget part(AddDataDetailsPart part) => AddDataDetailsContent(
      credential: d,
      faq: faq,
      heroKey: issueHeroKey,
      titleKey: _titleKey("details"),
      howIntro: howIntro,
      part: part,
    );
    // A phone held sideways: the card, its name and the intro at the left,
    // what you get at the right; the way on is in the bar.
    final split = useSheetColumns(context)
        ? SheetSplit(
            start: [part(AddDataDetailsPart.card)],
            end: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [part(AddDataDetailsPart.rest)],
            ),
          )
        : null;
    return GlassSheetPage(
      // The sheet's first page has no back: its close button is the way out,
      // where back is on the pages after it. Otherwise left by back or by
      // dragging its header down.
      closable: _direct,
      closeAtStart: true,
      // "Add {name}" names the page; the card's name is its heading, and
      // the bar shows the title only once that has scrolled away.
      title: context.tr("data.add.details.title_add", {"name": d.name}),
      titleWidget: IssueRequestorPill.maybe(subject),
      titleWidgetCentred: true,
      titleUnder: _titleKey("details"),
      onBack: _direct ? null : _issueLeave,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      split: split != null,
      action: action,
      bottomInBar: true,
      bottom: IssueSheetProgress(step: 1, total: total),
      child:
          split ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
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
    final state = nestedId == null
        ? null
        : ref.watch(sessionStateProvider(nestedId)).value;
    if (state != null && nestedId != null && _openIdStep(state)) {
      return _buildOpenIdStep(state, nestedId);
    }
    final awaiting =
        nestedId != null &&
        ref.watch(sessionAwaitingInteractionProvider(nestedId));
    // After "Add", and under "Success" (sliding away as it comes in), the
    // offer as it was: the session has moved on by then.
    final current = state != null && _isOffer(state) && !awaiting
        ? state
        : null;
    if (current != null) _lastOffer = current;
    final offer =
        current ?? (issueAdded != null || _granted ? _lastOffer : null);
    final cards = offer?.offeredCredentials ?? const <schemaless.Credential>[];

    // Inside a request, a card whose value is not what the request needs
    // does not count: trying again comes first, adding it anyway second.
    final request = issueRequest;
    final mismatched =
        request != null &&
        issuanceMismatches(
          cards,
          request.disclosurePlan?.issueDuringDisclosure?.steps ?? const [],
        ).isNotEmpty;
    final single = cards.any((c) => c.isSingleton);
    final grant = offer == null || nestedId == null
        ? null
        : () => _grant(nestedId);
    // Nobody vouches for the issuer: adding becomes "Add anyway", neutral,
    // with the reason above it and a red wash at the top, as sharing with a
    // requestor nobody vouches for.
    final issuer = cards.firstOrNull?.issuer;
    final risky =
        !mismatched &&
        issuer != null &&
        requestorTrustOf(issuer) == RequestorTrust.unknown;
    final action = mismatched
        ? SheetAction(
            key: const Key("sheet_issue_retry"),
            label: context.tr(
              single ? "share.offer.dont_replace" : "share.offer.retry",
            ),
            onTap: single ? issueClose : _retry,
          )
        : SheetAction(
            key: const Key("sheet_issue_add"),
            label: risky
                ? context.tr("issuance.question.add_anyway")
                : issuanceAddLabel(context, cards.length),
            neutral: risky,
            // Under way once tapped, until "Success" comes in.
            busy: awaiting,
            onTap: grant,
          );
    final anyway = mismatched
        ? Center(
            child: TextLink(
              key: const Key("sheet_issue_add"),
              label: context.tr(
                single
                    ? "share.offer.replace_anyway"
                    : "share.offer.add_anyway",
              ),
              onPressed: awaiting ? null : grant,
            ),
          )
        : null;
    // Above the button: why it says "anyway" for an issuer nobody vouches
    // for (no progress then: it is the last step anyway); else the progress.
    final bottom = risky
        ? IssuanceRiskyReason(
            issuer: issuer,
            textAlign: useSheetColumns(context)
                ? TextAlign.start
                : TextAlign.center,
          )
        : IssueSheetProgress.lastStep(total);
    final content = offer == null ? null : _offerContent(offer);
    final question = issuer == null
        ? null
        : IssuerHeading(
            issuer: issuer,
            count: cards.length,
            titleKey: _titleKey("issuance"),
            logoKey: _issuerLogoFrom,
            onTrust: () => _openIssuerPage(issuer),
          );
    final loading = _loading();
    // The cards: their values in tiles, the mismatch note above them.
    List<Widget> cardsAndValues(IssuanceOffer content) => [
      const YouGetLabel(),
      ?content.note(context),
      ...content.receives(context),
      ?anyway,
    ];
    final sideways = useSheetColumns(context);
    final page = GlassSheetPage(
      // The issuer names the page; the question is its heading, and the
      // bar shows the issuer once that has scrolled away.
      title: issuer?.name ?? context.tr("issuance.title"),
      titleWidget: IssueRequestorPill.maybe(subject),
      titleWidgetCentred: true,
      titleUnder: _titleKey("issuance"),
      // Back declines this issuance: on the details again, to try again.
      onBack: issueBack,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      action: action,
      // The progress in the bar sideways; the reason stays with the button.
      bottomInBar: !risky,
      bottom: bottom,
      split: sideways,
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
                      spacing: 8,
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
    child: Center(child: LoadingIndicator()),
  );

  /// What the offer holds: the card(s) and their values.
  IssuanceOffer _offerContent(SessionState offer) =>
      IssuanceOffer(cards: offer.offeredCredentials!, forRequest: issueRequest);

  /// Back to the step before the issuance (the website, the code), to try
  /// again after a card that does not count came back.
  void _retry() {
    issueBack();
    setState(() => _opened = false);
  }

  /// OpenID4VCI's transaction code or authorization-code step, as a page.
  /// Back declines the issuance.
  Widget _buildOpenIdStep(SessionState state, int sessionId) {
    if (state.status == SessionStatus.requestPreAuthorizedCode) {
      final parameters = state.transactionCodeParameters;
      if (parameters == null) {
        // Granted at once (see _onNested); the next state follows.
        return GlassSheetPage(
          // Left by dragging its header down: no close button.
          closable: false,
          title: context.tr("issuance.title"),
          onBack: () => _dismissNested(sessionId),
          child: _loading(),
        );
      }
      return OpenID4VCIPreAuthTxCodeScreen(
        inSheet: true,
        sessionId: sessionId,
        issuedCredentials: state.offeredCredentialTypes ?? const [],
        transactionCodeParameters: parameters,
        onSubmit: (code) => _grantPreAuthorizedCode(sessionId, code),
        onDismiss: () => _dismissNested(sessionId),
      );
    }
    // The issuer's login in the browser: the website page of adding a
    // card, as for a card from a website.
    final url = state.authorizationRequestUrl!;
    return IssueWebsiteStep(
      key: const Key("sheet_openid4vci_authcode"),
      title: context.tr("issuance.authorization_code.pending.title"),
      host: hostOf(url) ?? state.requestor.name,
      issuer: state.requestor.name,
      opened: _vciOpened.contains(sessionId),
      onOpen: () async {
        setState(() => _vciOpened.add(sessionId));
        await _repo.authenticateOpenID4VCI(url);
      },
      onBack: () => _dismissNested(sessionId),
    );
  }

  Widget _buildSuccess(
    List<schemaless.Credential> cards,
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
            padding: const EdgeInsets.only(top: 8),
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
        style: palette
            .display(24, weight: FontWeight.w700)
            .copyWith(height: 30 / 24, color: palette.text),
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
      return GlassSheetPage(
        title: context.tr("issuance.success_feedback.header"),
        titleWidget: IssueRequestorPill.maybe(subject),
        titleWidgetCentred: true,
        titleUnder: _titleKey("done"),
        action: action,
        closable: false,
        split: true,
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
    return GlassSheetPage(
      title: context.tr("issuance.success_feedback.header"),
      titleWidget: IssueRequestorPill.maybe(subject),
      titleWidgetCentred: true,
      titleUnder: _titleKey("done"),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      action: action,
      closable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          if (cards.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 90), child: received),
          DefaultTextStyle.merge(
            textAlign: TextAlign.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Center(child: heading),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
  String issueSuccessText(List<schemaless.Credential> cards) => context.tr(
    cards.length > 1
        ? "issuance.success_feedback.added_many"
        : "issuance.success_feedback.added_one",
    {"name": cards.firstOrNull?.name ?? "", "count": "${cards.length}"},
  );

  @override
  SheetAction issueSuccessAction(List<schemaless.Credential> cards) =>
      SheetAction(
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
class _NestedPin extends ConsumerStatefulWidget {
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
  ConsumerState<_NestedPin> createState() => _NestedPinState();
}

class _NestedPinState extends ConsumerState<_NestedPin> {
  late final _repo = ref.read(irmaRepositoryProvider);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionStateProvider(widget.sessionId)).value;
    final awaiting = ref.watch(
      sessionAwaitingInteractionProvider(widget.sessionId),
    );
    return GlassSheetPage(
      // Left by dragging its header down: no close button.
      closable: false,
      title: FlutterI18n.translate(context, "issuance.title"),
      onBack: widget.onCancel,
      titleWidget: IssueRequestorPill.maybe(widget.subject),
      titleWidgetCentred: true,
      // The pad fills the page and scales itself to it; it does not scroll.
      // It keeps clear of the home indicator itself (YiviPinScreen), so the
      // link under the keypad sits as low as on the full-screen PIN.
      scrolls: false,
      childClearsBottom: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SessionPinEntryScreen(
        key: const Key("sheet_pin"),
        inSheet: true,
        title: "issuance.title",
        detail: state == null
            ? null
            : sessionPinDetail(
                context,
                kind: "issuance",
                requestor: state.requestor.name,
              ),
        remainingAttempts: state?.remainingPinAttempts,
        blockedTimeSeconds: state?.pinBlockedTimeSeconds,
        submitting: awaiting,
        maxPinSize: (ref.watch(longPinProvider).value ?? false) ? 16 : 5,
        onPinEntered: (pin) => _repo.enterSessionPin(widget.sessionId, pin),
        onCancel: widget.onCancel,
      ),
    );
  }
}
