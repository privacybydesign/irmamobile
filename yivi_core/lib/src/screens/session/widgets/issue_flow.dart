import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart" show DocumentType;

import "../../../data/irma_repository.dart";
import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../providers/email_issuance_provider.dart";
import "../../../providers/external_issuer_provider.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../providers/nested_issuance_host_provider.dart";
import "../../../providers/schemaless_credential_store_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../providers/sms_issuance_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../util/navigation.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/glass/sheet_action_row.dart";
import "../../../widgets/loading_indicator.dart";
import "../../add_data/add_data_details_content.dart";
import "../../embedded_issuance_flows/documents/document_sheet_step.dart";
import "../../embedded_issuance_flows/widgets/contact_sheet_step.dart";
import "../../error/session_error_screen.dart";
import "../models/disclosure_view_model.dart";
import "issuance_permission.dart";
import "issuance_success_screen.dart";
import "issue_sheet_progress.dart";
import "issue_website_step.dart";
import "openid4vci_preauth_txcode_screen.dart";
import "session_pin_entry_screen.dart";

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

  /// The type the user is adding; null while on the sheet's root page.
  CredentialDescriptor? issueAdding;

  /// The sheet opened straight on [issueAdding] (a card to get again, or
  /// the only one a request can use): its details are the sheet's first
  /// page, with nothing to go back to. Leaving them closes the sheet.
  bool get issueDirect => _direct;
  bool _direct = false;

  /// Opens the sheet straight on [d]'s details; call from the host's
  /// initState. Null: the sheet opens on its root page.
  void issueStartWith(CredentialDescriptor? d) {
    issueAdding = d;
    _direct = d != null;
  }

  /// There is something else to choose than the card being added: the
  /// website step then offers "Choose something else".
  bool get issueHasOtherChoices => false;

  /// "Choose something else" on the website step: adding stops (after
  /// asking, once the website was opened) and the sheet's root page shows.
  Future<void> issueChooseOther() async {
    if (_opened && !await issueConfirmStop(closing: false)) return;
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

  /// The last offer shown, for the offer page while "Success" covers it.
  SessionState? _lastOffer;

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
  bool get issueStarted =>
      issueAdding != null && issueAdded == null && !_onDetails;

  /// The details of the type being added are the page on top: no step
  /// after them is open and no issuance is running.
  bool get _onDetails =>
      !_website &&
      _contact == null &&
      _document == null &&
      _nestedId == null &&
      !_pin;

  String _inSentence(String name) => inSentence(
    name,
    language: FlutterI18n.currentLocale(context)?.languageCode,
  );

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
  /// the details are the sheet's first page ([issueDirect]), the sheet
  /// closes instead.
  void issueLeave() {
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
    _nestedId = null;
    _pinShown = false;
    _lastOffer = null;
  }

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
  Future<void> _add(CredentialDescriptor d) async {
    beforeIssueAdd(d);
    final open = ref.read(issuerOpenerProvider);
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
    if (flow != null) {
      // Not one of the documents the sheet knows: its own screens, from the
      // page behind the sheet.
      final navigator = Navigator.of(context);
      final pageContext = navigator.context;
      navigator.pop();
      await open(pageContext, d, ref);
      return;
    }
    // The issuer's website: first the page that says so.
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
    if (_opened && !await issueConfirmStop(closing: false)) return;
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
  Future<bool> issueConfirmStop({bool closing = true}) async {
    final d = issueAdding;
    if (d == null || !issueStarted) return true;
    final stop =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => GlassDialog(
            cardKey: const Key("sheet_stop_dialog"),
            title: context.tr("share.sheet.stop_title", {
              "name": _inSentence(d.name),
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

  /// Back in the sheet: one step back, or from the details to the root page.
  /// The sheet: its own [root] page (under the key [rootKey]) and then the
  /// flow's pages, asking before it closes once adding has started. Opened
  /// on one card, the flow's first page takes the root's place.
  Widget issueSheet({
    required String rootKey,
    required Widget Function() root,
    required VoidCallback onBack,
  }) {
    // Popped, however (its close button, a drag, a tap outside, Done): the
    // sheet keeps its pages while it goes.
    final route = ModalRoute.of(context);
    if (route != null && !route.isActive && !_closing) _startClosing();
    return GlassSheetConfirmDismiss(
      ask: issueStarted,
      confirm: issueConfirmStop,
      // On a phone held upright the close button stays at the top right on
      // every page of adding.
      child: SheetKeepsClose(
        child: GlassSheetPages(
          onBack: onBack,
          pages: _closing && _shownPages != null
              ? _shownPages!
              : _shownPages = [
                  if (!issueDirect || issueAdding == null)
                    KeyedSubtree(key: ValueKey(rootKey), child: root()),
                  ...issueFlowPages(),
                ],
        ),
      ),
    );
  }

  void issueBack() {
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
      setState(() {
        _document = null;
        _faceCheck = false;
      });
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
      issueLeave();
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
          setState(() => _nestedId = null);
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

  void _grant(int sessionId) => _repo.grantSession(sessionId);

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
            pinned: IssueSheetProgress(subject: subject, step: 2, total: total),
            subtitle: IssueSheetRequestorLine(subject: subject),
            requestor: issueRequest?.requestor.name,
            onOther: issueHasOtherChoices ? issueChooseOther : null,
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
            onBack: () => setState(() {
              _document = null;
              _faceCheck = false;
            }),
            onStopped: issueLeave,
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
      // "Success": a page of its own, coming in forward over the offer (or
      // the PIN).
      if (issueAdded case final added?)
        KeyedSubtree(
          key: ValueKey(("done", nested)),
          child: _buildSuccess(added, subject, total),
        ),
    ];
  }

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
      if (nested != null && (_pin || (issueAdded != null && _pinShown)))
        KeyedSubtree(
          key: ValueKey(("pin", nested)),
          child: _NestedPin(
            sessionId: nested,
            subject: subject,
            total: 0,
            onCancel: () => _dismissNested(nested),
          ),
        ),
      if (issueAdded case final added?)
        KeyedSubtree(
          key: ValueKey(("done", nested)),
          child: _buildSuccess(added, subject, 0),
        ),
    ];
  }

  /// Step 1 (and 2, while the website is open): what the card is, as on
  /// the add-data page.
  Widget _buildDetails(
    CredentialDescriptor d,
    IssueSheetSubject subject,
    int total,
  ) {
    final host = hostOf(d.issueURL) ?? "";
    final faq = _faqFor(d.credentialId);
    // A card from an issuer's website: say up front that adding goes there
    // (the next page says it again, with the way there).
    final external =
        ref.watch(
          externalIssuerStatusProvider((
            credentialId: d.credentialId,
            issueUrl: d.issueURL,
          )),
        ) !=
        ExternalIssuerStatus.notExternal;
    // One way on: dragging the sheet down and back are the way out.
    final action = SheetAction(
      key: const Key("sheet_go_button"),
      label: context.tr("data.add.details.get_button"),
      onTap: () => _add(d),
    );
    // Where "Add" goes: at the foot of what the card is.
    final hostNote = external
        ? _HostNote(
            key: const Key("sheet_external_note"),
            text: context.tr("data.add.details.external_note", {"host": host}),
          )
        : null;
    // During a request: that the requestor only gets what they ask, when
    // the card holds more than that.
    final asked = d.attributes.where((a) => a.requestedValue != null).length;
    final holdsMore = asked > 0 && asked < d.attributes.length;
    final howIntro = switch (_repo.embeddedFlowOf(d.credentialId)) {
      EmbeddedFlow.email => context.tr("data.add.details.how_email"),
      EmbeddedFlow.phone => context.tr("data.add.details.how_phone"),
      EmbeddedFlow.document when documentTypeOf(d.credentialId) != null =>
        context.tr("data.add.details.how_document"),
      _ => null,
    };
    Widget part(AddDataDetailsPart part, {double cardWidth = 220}) =>
        AddDataDetailsContent(
          credential: d,
          faq: faq,
          forRequestor: holdsMore ? issueRequest?.requestor.name : null,
          howIntro: howIntro,
          part: part,
          cardWidth: cardWidth,
        );
    // A phone held sideways: the card and its name at the left, what it
    // is and what you get at the right; the way on is in the bar.
    final split = useSheetColumns(context)
        ? SheetSplit(
            start: [part(AddDataDetailsPart.card, cardWidth: 250)],
            end: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [part(AddDataDetailsPart.rest), ?hostNote],
            ),
          )
        : null;
    return GlassSheetPage(
      // The sheet's first page has no back: its close button is the way out,
      // where back is on the pages after it. Otherwise left by back or by
      // dragging its header down.
      closable: _direct,
      closeAtStart: true,
      // "Add {name}": the page is about adding it (the progress under the
      // bar says where in adding it you are).
      title: context.tr("data.add.details.title_add", {"name": d.name}),
      onBack: _direct ? null : issueLeave,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      split: split != null,
      action: action,
      pinned: IssueSheetProgress(subject: subject, step: 1, total: total),
      subtitle: IssueSheetRequestorLine(subject: subject),
      child:
          split ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [part(AddDataDetailsPart.all), ?hostNote],
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
    // Under "Success" (sliding away as it comes in) the offer as it was:
    // the session has moved on by then.
    final current = state != null && _isOffer(state) && !awaiting
        ? state
        : null;
    if (current != null) _lastOffer = current;
    final offer = current ?? (issueAdded != null ? _lastOffer : null);
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
            label: request != null
                ? (cards.length > 1
                      ? context.tr("share.offer.add_many", {
                          "count": "${cards.length}",
                        })
                      : context.tr("share.offer.add"))
                : cards.length > 1
                ? context.tr("issuance.add_many", {"count": "${cards.length}"})
                : context.tr("issuance.add"),
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
    // A phone held sideways: the card(s) at the left, the question and the
    // values at the right; the way on is in the bar.
    if (useSheetColumns(context)) {
      final content = offer == null ? null : _offerContent(offer);
      return GlassSheetPage(
        // Left by dragging its header down: no close button.
        closable: false,
        title: context.tr("issuance.title"),
        onBack: issueBack,
        action: action,
        pinned: IssueSheetProgress.lastStep(subject, total),
        subtitle: IssueSheetRequestorLine.maybe(subject),
        split: true,
        child: SheetSplit(
          key: content == null ? null : const Key("sheet_issuance"),
          start: content == null
              ? const []
              : content.overview(context, cardWidth: 230),
          end: content == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: LoadingIndicator()),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    _question(cards),
                    ...content.receives(context),
                    ?anyway,
                  ],
                ),
        ),
      );
    }
    return GlassSheetPage(
      // Left by dragging its header down: no close button.
      closable: false,
      title: context.tr("issuance.title"),
      // Back declines this issuance: on the details again, to try again.
      onBack: issueBack,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      action: action,
      pinned: IssueSheetProgress.lastStep(subject, total),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          if (offer == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Center(child: LoadingIndicator()),
            )
          else
            KeyedSubtree(
              key: const Key("sheet_issuance"),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [..._offer(offer), ?anyway],
              ),
            ),
        ],
      ),
    );
  }

  /// What the offer holds: the card(s), their chips and their values.
  IssuanceOffer _offerContent(SessionState offer) {
    final cards = offer.offeredCredentials!;
    final returned = _opened && cards.any((c) => _launched(c.credentialId))
        ? cards.first.issuer.name
        : null;
    return IssuanceOffer(
      cards: cards,
      forRequest: issueRequest,
      returnedFromIssuer: returned,
      showRequestChip: false,
    );
  }

  /// Back to the step before the issuance (the website, the code), to try
  /// again after a card that does not count came back.
  void _retry() {
    issueBack();
    setState(() => _opened = false);
  }

  /// "Do you want to add this to your Yivi app?"; inside a request, "{issuer}
  /// sends you this card". Smaller in the right column of a phone held
  /// sideways.
  Widget _question(List<schemaless.Credential> cards) {
    final palette = YiviPalette.of(context);
    final landscape = useSheetColumns(context);
    final count = cards.length;
    final issuer = cards.firstOrNull?.issuer.name ?? "";
    final request = issueRequest;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        header: true,
        child: Text(
          request != null
              ? (count > 1
                    ? context.tr("share.offer.question_many", {
                        "issuer": issuer,
                        "count": "$count",
                      })
                    : context.tr("share.offer.question", {"issuer": issuer}))
              : count > 1
              ? context.tr("issuance.question_many", {"count": "$count"})
              : context.tr("issuance.description"),
          style: landscape
              ? palette
                    .display(17, weight: FontWeight.w700)
                    .copyWith(height: 23 / 17, color: palette.text)
              : palette
                    .display(22)
                    .copyWith(height: 30 / 22, color: palette.heading),
        ),
      ),
    );
  }

  List<Widget> _offer(SessionState offer) {
    final cards = offer.offeredCredentials!;
    final content = _offerContent(offer);
    final question = _question(cards);
    final requestor = issueRequest?.requestor.name;
    final palette = YiviPalette.of(context);
    return [
      question,
      if (requestor != null && cards.length > 1)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            context.tr("share.offer.lead_many", {"requestor": requestor}),
            key: const Key("sheet_offer_lead"),
            style: palette
                .body(15)
                .copyWith(height: 22 / 15, color: palette.heading),
          ),
        ),
      ...content.overview(context, cardWidth: 358),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content.receives(context),
      ),
    ];
  }

  bool _launched(String credentialId) =>
      ref
          .watch(websiteLaunchedCredentialsProvider)
          .value
          ?.contains(credentialId) ??
      false;

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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Center(child: LoadingIndicator()),
          ),
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
    final linkButton = link == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextLink(
                key: link.key,
                label: link.label,
                onPressed: link.onTap,
              ),
            ),
          );
    // The bar says "Success"; what was added is the heading below. Done:
    // no progress, no close button; the way on is the way out.
    // A phone held sideways: the card with its check and the words at the
    // left; what is now in the app at the right.
    if (useSheetColumns(context)) {
      return GlassSheetPage(
        title: context.tr("issuance.success_feedback.header"),
        action: action,
        closable: false,
        subtitle: IssueSheetRequestorLine.maybe(subject),
        split: true,
        child: SheetSplit(
          start: [
            if (cards.isNotEmpty)
              Padding(
                // Room for the check over the card's corner.
                padding: const EdgeInsets.only(top: 14, right: 80),
                child: IssuanceReceived(cards: cards, cardKeys: issueAddedKeys),
              ),
            Text(
              context.tr("issuance.success_feedback.added_header"),
              style: palette
                  .display(24, weight: FontWeight.w700)
                  .copyWith(color: palette.heading),
            ),
            Text(
              issueSuccessText(cards),
              key: const Key("sheet_added_text"),
              style: palette.body(15).copyWith(height: 22 / 15),
            ),
          ],
          end: Column(
            key: const Key("sheet_added_values"),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (cards.isNotEmpty)
                ...IssuanceOffer(
                  cards: cards,
                  showRequestChip: false,
                ).receives(context, headingKey: "data.add.in_your_app"),
              ?linkButton,
            ],
          ),
        ),
      );
    }
    return GlassSheetPage(
      title: context.tr("issuance.success_feedback.header"),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      action: action,
      closable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          if (cards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: IssuanceReceived(cards: cards, cardKeys: issueAddedKeys),
            ),
          Text(
            context.tr("issuance.success_feedback.added_header"),
            textAlign: TextAlign.center,
            style: palette
                .display(26, weight: FontWeight.w700)
                .copyWith(color: palette.heading),
          ),
          Text(
            issueSuccessText(cards),
            key: const Key("sheet_added_text"),
            textAlign: TextAlign.center,
            style: palette.body(16).copyWith(height: 24 / 16),
          ),
          ?linkButton,
        ],
      ),
    );
  }
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
      IssueSheetSubject.card(d);

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

/// Where adding happens, quietly at the foot of the card's details.
class _HostNote extends StatelessWidget {
  final String text;

  const _HostNote({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.language_rounded, size: 16, color: palette.link),
          ),
          Expanded(
            child: Text(
              text,
              style: palette
                  .body(13)
                  .copyWith(height: 18 / 13, color: palette.heading),
            ),
          ),
        ],
      ),
    );
  }
}

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
  bool _longPin = false;

  @override
  void initState() {
    super.initState();
    _repo.preferences.getLongPin().first.then((value) {
      if (mounted) setState(() => _longPin = value);
    });
  }

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
      pinned: IssueSheetProgress.lastStep(widget.subject, widget.total),
      subtitle: IssueSheetRequestorLine.maybe(widget.subject),
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
        maxPinSize: _longPin ? 16 : 5,
        onPinEntered: (pin) => _repo.enterSessionPin(widget.sessionId, pin),
        onCancel: widget.onCancel,
      ),
    );
  }
}
