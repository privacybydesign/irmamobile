import "dart:io";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../data/irma_repository.dart";
import "../../data/session_repository.dart";
import "../../models/native_events.dart";
import "../../models/return_url.dart";
import "../../models/session.dart";
import "../../models/session_state.dart";
import "../../models/session_user_interaction.dart";
import "../../providers/email_linking_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/session_flow_provider.dart";
import "../../providers/session_state_provider.dart";
import "../../providers/session_user_choices_provider.dart";
import "../../sentry/sentry.dart";
import "../../theme/yivi_tone.dart";
import "../../util/after_frame.dart";
import "../../util/haptics.dart";
import "../../util/i18n.dart";
import "../../util/navigation.dart";
import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/yivi_spinner.dart";
import "../error/session_error_screen.dart";
import "../error/tx_code_lockout_screen.dart";
import "call_info_screen.dart";
import "models/disclosure_view_model.dart";
import "models/session_outcome.dart";
import "models/session_view.dart";
import "widgets/arrow_back_screen.dart";
import "widgets/disclosure_feedback_screen.dart";
import "widgets/disclosure_share_screen.dart";
import "widgets/issuance_permission.dart";
import "widgets/issuance_success_screen.dart";
import "widgets/issue_website_step.dart";
import "widgets/openid4vci_preauth_txcode_screen.dart";
import "widgets/pairing_required.dart";
import "widgets/session_pin_entry_screen.dart";
import "widgets/session_result.dart";
import "widgets/session_scaffold.dart";

/// Displays the current [SessionState] for a given session ID.
///
/// Pushed by [handlePointer] immediately after dispatching `NewSessionEvent`,
/// with a Dart-allocated session id. While Go has not yet emitted the first
/// state, the existing `asyncSession.isLoading` branch renders the loading
/// screen — this is the spinner during the QR-scan → first-state window.
/// The screen pops itself when the session status becomes
/// [SessionStatus.dismissed].
class SessionScreen extends ConsumerStatefulWidget {
  final int sessionId;
  final bool hasUnderlyingSession;

  const SessionScreen({
    super.key,
    required this.sessionId,
    this.hasUnderlyingSession = false,
  });

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  late final IrmaRepository _repo;
  late final SessionRepository _sessions;
  late SessionFlow _flow;

  /// The state of the last view: what dispose and the close of an error
  /// read, when ref can no longer be used.
  SessionState? _lastState;

  /// The cards the user agreed to share, for "What you shared" on the
  /// success screen.
  List<SelectableCredentialInstance> _sharedInstances = const [];

  /// The request this (nested) session runs for, kept once seen: on
  /// success it is "Back to {requestor}" even if the request is gone.
  SessionState? _underlying;

  /// What the success screen is; decided once, when the session went
  /// through.
  SessionOutcome? _outcome;

  /// Read once: what the session hands back to the caller differs.
  final _platform = Platform.isIOS
      ? SessionPlatform.ios
      : SessionPlatform.android;

  /// Set when a return-URL launch threw. Renders the error screen until the
  /// user closes it; the close handler then skips the silent reopen.
  SessionError? _returnUrlError;

  /// True once the user closed an error on a session that has no way back to
  /// its caller other than the iOS status-bar back link. Replaces the session
  /// body with [ArrowBack] until they leave the app.
  bool _showArrowBack = false;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(irmaRepositoryProvider);
    _sessions = ref.read(sessionRepositoryProvider);
    ref.listenManual(
      sessionFlowProvider(widget.sessionId),
      _onView,
      fireImmediately: true,
    );
  }

  /// What runs once when the session comes to a new view: build only draws.
  void _onView(SessionView? previous, SessionView next) {
    if (previous?.runtimeType == next.runtimeType) return;
    switch (next) {
      case SessionSucceeded(:final state):
        Haptics.success();
        final outcome = _outcome = _outcomeOf(state);
        _runOutcome(outcome);
      case SessionFailed():
        Haptics.error();
      // Pop back to the previous screen (scanner, home, or the underlying
      // session). Clear so an abandoned in-app launch doesn't leak into the
      // next session.
      case SessionDismissed():
        _repo.clearInAppLaunches();
        afterFrame(() {
          if (widget.hasUnderlyingSession) {
            context.popToUnderlyingSession();
          } else {
            Navigator.of(context).pop();
          }
        });
      default:
    }
  }

  /// What the success screen is for [session]. The first time, it reads
  /// whether the issuance was launched in the app and forgets the launches.
  SessionOutcome _outcomeOf(SessionState session) {
    final keyshareLink =
        ref.read(emailLinkingProvider).disclosureSessionId == widget.sessionId;
    final flow = ref.read(sessionFlowProvider(widget.sessionId).notifier);
    return sessionOutcomeOf(
      SessionFacts(
        type: session.type,
        returnUrl: session.parsedClientReturnUrl,
        platform: _platform,
        secondDevice: session.continueOnSecondDevice,
        inAppLaunched: !keyshareLink && flow.inAppLaunchedOnSuccess(session),
        forRequest: widget.hasUnderlyingSession,
        keyshareLink: keyshareLink,
      ),
    );
  }

  /// What [outcome] does once, after the frame that shows it.
  void _runOutcome(SessionOutcome outcome) {
    switch (outcome) {
      case EmailLinked():
        final linking = ref.read(emailLinkingProvider.notifier);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          linking.markLinked();
        });
      case OpenReturnUrl(:final url):
        afterFrame(() => _goToReturnUrl(url));
      case IssuedToBackground():
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _repo.bridgedDispatch(AndroidSendToBackgroundEvent());
          _popToUnderlyingOrHome();
        });
      default:
    }
  }

  @override
  void dispose() {
    // Dismiss unless we've already observed a terminal state. A null
    // `_lastState` means Go hasn't emitted any state yet — that
    // window exists because SessionScreen is now pushed before the first
    // SessionStateEvent — and backing out during it must still dismiss the
    // Go-side session.
    // We use cached values because ref is unsafe to use during dispose.
    final status = _lastState?.status;
    if (!(status?.isTerminal ?? false)) {
      _sessions.dismissSession(widget.sessionId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(sessionFlowProvider(widget.sessionId));
    _flow = ref.read(sessionFlowProvider(widget.sessionId).notifier);
    _lastState = view.state;
    if (widget.hasUnderlyingSession) {
      _underlying =
          ref.watch(underlyingDisclosureProvider(widget.sessionId)).value ??
          _underlying;
    }

    // Takes precedence over every session state: the session is over, and the
    // only thing left for the user to do is tap the iOS back link.
    if (_showArrowBack) {
      return const ArrowBack(type: ArrowBackType.error);
    }

    return switch (view) {
      // No state yet, waiting for Go after a tap, or an OpenID4VCI code
      // being granted.
      SessionWaiting(:final state) => _buildLoadingScreen(state),
      // Popping (see _onView).
      SessionDismissed(:final state) => _buildLoadingScreen(state),
      SessionSucceeded(:final state) => _buildSuccess(
        state,
        _outcome ?? _outcomeOf(state),
      ),
      SessionPairing(:final state) => PairingRequired(
        pairingCode: state.pairingCode ?? "",
        requestor: state.requestor,
        onDismiss: _dismissSession,
      ),
      // An issuance that asks for data first: one screen with what is shared
      // and the card that is received, and one button for both.
      SessionOffer(:final state) => IssuancePermission(
        issuedCredentials: state.offeredCredentials!,
        forRequest: _underlying,
        session: state,
        onDismiss: _dismissSession,
        onGivePermission: () => _grantPermission(const []),
      ),
      // The whole request at once; a card that is not in the app yet is an
      // empty spot, added in the Change sheet.
      SessionShare(:final state) => DisclosureShareScreen(
        session: state,
        onDismiss: _showDismissDialog,
        onClose: _dismissSession,
        onShare: _grantPermission,
      ),
      SessionPin() => SessionPinPage(sessionId: widget.sessionId),
      SessionTxLockout() => TxCodeLockoutScreen(onTapClose: _closeSession),
      SessionFailed(:final error) => _buildError(error),
      SessionTxCode(:final state, :final parameters) =>
        OpenID4VCIPreAuthTxCodeScreen(
          sessionId: widget.sessionId,
          issuedCredentials: state.offeredCredentialTypes!,
          transactionCodeParameters: parameters,
          onSubmit: _flow.grantPreAuthorizedCode,
          onDismiss: _dismissSession,
        ),
      // The issuer's login in the browser, as the website step of adding a
      // card in a sheet. The user opens it from here: shown on first entry
      // and whenever the user returns to the app without finishing there.
      SessionAuthCode(:final state, :final url) => IssueWebsiteScreen(
        titleKey: "issuance.authorization_code.pending.title",
        host: hostOf(url) ?? state.requestor.name,
        issuer: state.requestor.name,
        onOpen: _flow.openAuthorization,
        onDismiss: _dismissSession,
      ),
    };
  }

  void _dismissSession() => _flow.dismiss();

  Future<void> _showDismissDialog() async {
    final confirmed = await showConfirmDialog(
      context,
      titleKey: "disclosure_permission.confirm_close_dialog.title",
      messageKey: "disclosure_permission.confirm_close_dialog.explanation",
      confirmKey: "disclosure_permission.confirm_close_dialog.confirm",
      cancelKey: "disclosure_permission.confirm_close_dialog.decline",
    );
    if (confirmed && mounted) _dismissSession();
  }

  String _getAppBarTitle(SessionState session) {
    return switch (session.type) {
      .issuance => "issuance.title",
      .signature => "disclosure.title",
      .disclosure => "disclosure.title",
    };
  }

  Widget _buildLoadingScreen(SessionState? session) {
    return SessionScaffold(
      body: Center(child: YiviSpinner()),
      onDismiss: _dismissSession,
      appBarTitle: session != null
          ? _getAppBarTitle(session)
          : "disclosure.title",
    );
  }

  void _grantPermission(List<DisclosureDisconSelection> disclosureChoices) {
    // What the share screen shared: the bundles in use, as it chose them.
    _sharedInstances = sharedInstancesOf(
      _lastState?.disclosurePlan?.disclosureChoicesOverview ??
          const <DisclosurePickOne>[],
      ref.read(sessionSelectionsProvider(widget.sessionId)),
    );
    _flow.grant(disclosureChoices);
  }

  Widget _buildSuccess(SessionState session, SessionOutcome outcome) {
    // "Shared with {requestor}", with what to do now.
    Widget shared({
      bool onOtherDevice = false,
      String? returnHost,
      VoidCallback? onReturn,
      bool goBackYourself = false,
      VoidCallback? onBackToWebsite,
    }) => DisclosureFeedbackScreen(
      isSignatureSession: session.type == .signature,
      message: session.type == .signature ? session.messageToSign : null,
      requestor: session.requestor,
      onDismiss: (_) => _popToUnderlyingOrHome(),
      shared: _sharedInstances,
      onOtherDevice: onOtherDevice,
      returnHost: returnHost,
      onReturn: onReturn,
      goBackYourself: goBackYourself,
      onBackToWebsite: onBackToWebsite,
    );

    return switch (outcome) {
      // The e-mail address is linked to the PIN.
      EmailLinked() => SessionResult(
        key: const Key("email_linked"),
        onClose: _popToUnderlyingOrHome,
        hero: const ToneDisc(
          icon: Icons.check_rounded,
          tone: YiviTone.success,
          size: 84,
          iconSize: 40,
        ),
        title: context.tr("email_linking.done.title"),
        text: context.tr("email_linking.done.body"),
        action: FancyPillButton(
          key: const Key("ok_button"),
          label: context.tr("action_feedback.ok"),
          onPressed: _popToUnderlyingOrHome,
        ),
      ),
      // Confirm what was added, then back to the request ("Back to
      // {requestor}").
      AddedForRequest() => IssuanceSuccessScreen(
        credentials: session.offeredCredentials ?? const [],
        backTo: _underlying?.requestor.name,
        onDismiss: (_) {
          if (mounted) context.popToUnderlyingSession();
        },
      ),
      // "Success", with the card flying into the data tab on OK.
      Added() => IssuanceSuccessScreen(
        credentials: session.offeredCredentials ?? const [],
        onDismiss: (_) => _popToUnderlyingOrHome(),
        flyHome: true,
      ),
      CallVia(:final url) => CallInfoScreen(
        otherParty: session.requestor.name,
        phoneNumber: url.phoneNumber,
        onContinue: () =>
            _openReturnUrl(url, alwaysExternal: true, popOnSuccess: true),
        onCancel: _closeSession,
      ),
      Shared(next: OtherDevice()) => shared(onOtherDevice: true),
      // A return URL that could not be opened: the error, until closed.
      Shared(next: ReturnTo()) || OpenReturnUrl()
          when _returnUrlError != null =>
        _buildError(_returnUrlError!),
      // After sharing, they first see what was shared, with "Back to
      // {host}" to go there.
      Shared(next: ReturnTo(:final host, :final url)) => shared(
        returnHost: host,
        onReturn: () => _goToReturnUrl(url),
      ),
      Shared(next: GoBackYourself()) => shared(goBackYourself: true),
      // Moves the task to the background so the OS surfaces the previous
      // app.
      Shared(next: BackToWebsite()) => shared(
        onBackToWebsite: () {
          _repo.bridgedDispatch(AndroidSendToBackgroundEvent());
          _popToUnderlyingOrHome();
        },
      ),
      // Opening (see _runOutcome).
      OpenReturnUrl() || IssuedToBackground() => _buildLoadingScreen(session),
      IssuedArrowBack() => const ArrowBack(type: .issuance),
    };
  }

  Future<void> _closeSession() async {
    final session = _lastState;
    // Nothing seen of the session: just leave.
    final close = session == null
        ? null
        : sessionCloseOf(
            SessionFacts(
              type: session.type,
              returnUrl: session.parsedClientReturnUrl,
              platform: _platform,
              secondDevice: session.continueOnSecondDevice,
              // Don't silently reopen the issuer's return URL when the user
              // originated this issuance from inside the app — they expect
              // to land back in Yivi, not bounced back to a browser.
              inAppLaunched:
                  _flow.inAppLaunched ??
                  _repo.didIssueInAppLaunchedCredential(session),
              forRequest: widget.hasUnderlyingSession,
              keyshareLink: false,
            ),
            error: _returnUrlError ?? session.error,
          );

    if (close?.reopen case final url?) {
      try {
        await _repo.openURLExternally(url.toString());
      } catch (e, st) {
        // The user is on the way out — don't surface a second error screen.
        reportError(e, st);
      }
    }

    // Clear so an abandoned in-app launch doesn't leak into the next
    // session. Safe to call even when nothing was launched.
    _repo.clearInAppLaunches();

    switch (close?.caller) {
      // iOS has no programmatic way back, so point at the status-bar back
      // link and stay put until the user leaves.
      case CallerReturn.arrowBack:
        if (mounted) setState(() => _showArrowBack = true);
        return;
      case CallerReturn.background:
        _repo.bridgedDispatch(AndroidSendToBackgroundEvent());
      case CallerReturn.none || null:
    }

    if (mounted) {
      context.popToUnderlyingSessionOrHome(
        hasUnderlyingSession: widget.hasUnderlyingSession,
      );
    }
  }

  /// Opens the return URL: in the in-app browser over home (popped first),
  /// or outside the app, popping once it opened so a failure can show the
  /// error screen.
  Future<void> _goToReturnUrl(ReturnURL returnUrl) async {
    if (returnUrl.isInApp) {
      _popToUnderlyingOrHome();
      await _openReturnUrl(
        returnUrl,
        alwaysExternal: false,
        popOnSuccess: false,
      );
    } else {
      await _openReturnUrl(returnUrl, alwaysExternal: true, popOnSuccess: true);
    }
  }

  void _popToUnderlyingOrHome() {
    if (!mounted) return;
    context.popToUnderlyingSessionOrHome(
      hasUnderlyingSession: widget.hasUnderlyingSession,
    );
  }

  Future<void> _openReturnUrl(
    ReturnURL url, {
    required bool alwaysExternal,
    required bool popOnSuccess,
  }) async {
    try {
      if (url.isInApp && !alwaysExternal) {
        await _repo.openURLinAppBrowser(url.toString());
      } else {
        await _repo.openURLExternally(url.toString());
      }
      if (popOnSuccess) _popToUnderlyingOrHome();
    } catch (e, st) {
      reportError(e, st);
      if (mounted) {
        Haptics.error();
        setState(() {
          _returnUrlError = SessionError(
            errorType: "clientReturnUrl",
            info: "the clientReturnUrl could not be handled",
            wrappedError: e.toString(),
          );
        });
      }
    }
  }

  Widget _buildError(SessionError error) {
    return SessionErrorScreen(error: error, onTapClose: _closeSession);
  }
}
