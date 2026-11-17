import "dart:io";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../data/irma_repository.dart";
import "../../models/native_events.dart";
import "../../models/return_url.dart";
import "../../models/session.dart";
import "../../models/session_state.dart";
import "../../models/session_user_interaction.dart";
import "../../providers/email_linking_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/session_flow_provider.dart";
import "../../providers/session_state_provider.dart";
import "../../sentry/sentry.dart";
import "../../util/after_frame.dart";
import "../../util/haptics.dart";
import "../../util/navigation.dart";
import "../../util/string.dart";
import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/yivi_spinner.dart";
import "../error/session_error_screen.dart";
import "../error/tx_code_lockout_screen.dart";
import "call_info_screen.dart";
import "models/session_view.dart";
import "widgets/arrow_back_screen.dart";
import "widgets/disclosure_feedback_screen.dart";
import "widgets/disclosure_share_screen.dart";
import "widgets/email_linked_screen.dart";
import "widgets/issuance_permission.dart";
import "widgets/issuance_success_screen.dart";
import "widgets/openid4vci_authcode_pending_screen.dart";
import "widgets/openid4vci_preauth_txcode_screen.dart";
import "widgets/pairing_required.dart";
import "widgets/session_pin_entry_screen.dart";
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

  /// True after dispatching openURLExternally / openURLinAppBrowser, so
  /// post-frame rebuilds of the success screen don't re-fire the side effect.
  bool _returnUrlSideEffectFired = false;

  /// Set when a return-URL launch threw. Renders the error screen until the
  /// user closes it; the close handler then skips the silent reopen.
  SessionError? _returnUrlError;

  /// Latched on the first `_buildSuccess` call for this session: true iff
  /// the finished issuance includes a credential the user launched
  /// in-app. We capture once and clear the launched set immediately so
  /// rebuilds keep returning the same decision.
  bool? _inAppLaunchedSuccess;

  /// True once the user closed an error on a session that has no way back to
  /// its caller other than the iOS status-bar back link. Replaces the session
  /// body with [ArrowBack] until they leave the app.
  bool _showArrowBack = false;

  /// True once the finished keyshare disclosure was recorded as a linked address.
  bool _emailLinkRecorded = false;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(irmaRepositoryProvider);
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
      _repo.dismissSession(widget.sessionId);
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
      // Auto-pop when dismissed — pop back to the previous screen
      // (scanner, home, or underlying session). Clear so an abandoned
      // in-app launch doesn't leak into the next session.
      SessionDismissed(:final state) => _buildDismissed(state),
      SessionSucceeded(:final state) => _buildSucceeded(state),
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
      // The user must tap "Open browser" on this screen to launch the issuer
      // flow. Shown on first entry and whenever the user returns to the app
      // without completing the browser flow.
      SessionAuthCode(:final state) => OpenID4VCIAuthCodePendingScreen(
        requestor: state.requestor,
        offeredCredentialTypes: state.offeredCredentialTypes!,
        onOpenBrowser: _flow.openAuthorization,
        onDismiss: _dismissSession,
      ),
    };
  }

  Widget _buildDismissed(SessionState session) {
    _repo.clearInAppLaunches();
    afterFrame(() {
      if (widget.hasUnderlyingSession) {
        context.popToUnderlyingSession();
      } else {
        Navigator.of(context).pop();
      }
    });
    return _buildLoadingScreen(session);
  }

  Widget _buildSucceeded(SessionState session) {
    Haptics.success();
    return _buildSuccess(session);
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
    _sharedInstances = _instancesFor(disclosureChoices);
    _flow.grant(disclosureChoices);
  }

  Widget _buildSuccess(SessionState session) {
    final linking = ref.read(emailLinkingProvider);

    // E-mail linking ends on its own screen once MijnYivi has the address.
    if (linking.disclosureSessionId == widget.sessionId) {
      if (!_emailLinkRecorded) {
        _emailLinkRecorded = true;
        final linkingNotifier = ref.read(emailLinkingProvider.notifier);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          linkingNotifier.markLinked();
        });
      }
      return EmailLinkedScreen(onDismiss: (_) => _popToUnderlyingOrHome());
    }

    // Latch the in-app-launched decision on first build, then clear the
    // launched set so abandoned launches don't leak into a future session.
    // Build runs multiple times; without latching, the cleared set would
    // flip the decision on subsequent builds.
    if (_inAppLaunchedSuccess == null) {
      _inAppLaunchedSuccess = _repo.didIssueInAppLaunchedCredential(session);
      _repo.clearInAppLaunches();
    }

    // An issuance during a request: confirm what was added, then back to
    // the request ("Back to {requestor}").
    if (widget.hasUnderlyingSession && session.type == .issuance) {
      return IssuanceSuccessScreen(
        credentials: session.offeredCredentials ?? const [],
        backTo: _underlying?.requestor.name,
        onDismiss: (_) {
          if (mounted) context.popToUnderlyingSession();
        },
      );
    }

    // The user originated this issuance from inside the app (add-data tap
    // or OpenID4VCI launch). Keep them in-app on finish — skip any return
    // URL the issuer set, and skip the iOS ArrowBack / Android background
    // fallbacks.
    // "Success", with the card flying into the data tab on OK.
    Widget issued() => IssuanceSuccessScreen(
      credentials: session.offeredCredentials ?? const [],
      onDismiss: (_) => _popToUnderlyingOrHome(),
      flyHome: true,
    );

    if (_inAppLaunchedSuccess!) return issued();

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

    final returnUrl = session.parsedClientReturnUrl;

    // A tel: return URL is device-agnostic — the phone is the device that
    // places the call — so surface the Call-via-Yivi screen regardless of
    // whether this is a same- or second-device session.
    if (returnUrl != null && returnUrl.isPhoneNumber) {
      return CallInfoScreen(
        otherParty: session.requestor.name,
        phoneNumber: returnUrl.phoneNumber,
        onContinue: () =>
            _openReturnUrl(returnUrl, alwaysExternal: true, popOnSuccess: true),
        onCancel: _closeSession,
      );
    }

    // Second-device session: the result lives on the other device, whose
    // browser started the session and honours any browser-kind return URL
    // there. Confirm success locally and do NOT open a browser on the phone —
    // opening it here would be a pointless redirect on the wrong device.
    // (tel: is handled above; it stays device-agnostic.)
    if (session.continueOnSecondDevice) {
      if (session.type == .issuance) return issued();
      return shared(onOtherDevice: true);
    }

    // Same-device session with a browser return URL (external / in-app): hand
    // the user back to where they started by opening it. After sharing, they
    // first sees what was shared, with "Back to {host}" to go there.
    if (returnUrl != null) {
      if (_returnUrlError != null) {
        return _buildError(_returnUrlError!);
      }
      if (session.type != .issuance) {
        return shared(
          returnHost: returnUrl.uri.host.withoutWww(),
          onReturn: () => _goToReturnUrl(returnUrl),
        );
      }
      if (!_returnUrlSideEffectFired) {
        _returnUrlSideEffectFired = true;
        afterFrame(() => _goToReturnUrl(returnUrl));
      }
      return _buildLoadingScreen(session);
    }

    // Same-device session: hand the user back to the calling app. iOS lacks a
    // programmatic way to do that: after sharing, the done screen says to tap
    // ◀ at the top left; after an issuance, ArrowBack. On Android, after
    // sharing, the done screen's "Back to the website" moves the task to the
    // background so the OS surfaces the previous app; after an issuance that
    // happens at once.
    if (Platform.isIOS && session.type != .issuance) {
      return shared(goBackYourself: true);
    }
    if (session.type != .issuance) {
      return shared(
        onBackToWebsite: () {
          _repo.bridgedDispatch(AndroidSendToBackgroundEvent());
          _popToUnderlyingOrHome();
        },
      );
    }
    if (Platform.isIOS) return const ArrowBack(type: .issuance);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo.bridgedDispatch(AndroidSendToBackgroundEvent());
      _popToUnderlyingOrHome();
    });
    return _buildLoadingScreen(session);
  }

  /// The candidate instances of the last disclosure plan the user picked in
  /// [choices], each carrying only the attributes that are disclosed.
  List<SelectableCredentialInstance> _instancesFor(
    List<DisclosureDisconSelection> choices,
  ) {
    final candidates = <String, SelectableCredentialInstance>{
      for (final pickOne
          in _lastState?.disclosurePlan?.disclosureChoicesOverview ??
              const <DisclosurePickOne>[])
        for (final bundle in pickOne.ownedOptions ?? const <DisclosureBundle>[])
          for (final instance in bundle.credentials) instance.hash: instance,
    };
    return [
      for (final choice in choices)
        for (final selected in choice.credentials)
          ?candidates[selected.credentialHash],
    ];
  }

  Future<void> _closeSession() async {
    final session = _lastState;
    final returnUrl = session?.parsedClientReturnUrl;
    // Don't silently reopen the issuer's return URL when the user
    // originated this issuance from inside the app — they expect to land
    // back in Yivi, not bounced back to a browser.
    final wasInAppLaunched =
        session != null && _repo.didIssueInAppLaunchedCredential(session);
    final shouldSilentReopen =
        returnUrl != null &&
        !returnUrl.isPhoneNumber &&
        // On a second-device session the browser lives on the other device;
        // reopening the return URL on the phone would be a pointless redirect.
        session?.continueOnSecondDevice != true &&
        session?.error?.errorType != "clientReturnUrl" &&
        _returnUrlError?.errorType != "clientReturnUrl" &&
        !wasInAppLaunched;

    if (shouldSilentReopen) {
      try {
        await _repo.openURLExternally(returnUrl.toString());
      } catch (e, st) {
        // The user is on the way out — don't surface a second error screen.
        reportError(e, st);
      }
    }

    // Clear so an abandoned in-app launch doesn't leak into the next
    // session. Safe to call even when nothing was launched.
    _repo.clearInAppLaunches();

    // Same-device session that set no return URL: the caller is whatever app
    // handed the session over, typically the browser the user started in.
    // Leaving them on the Yivi home screen strands them there — the retry
    // lives in the caller — so hand them back the same way _buildSuccess
    // does. Requestors that chain sessions rely on this: a failure mid-chain
    // is recoverable, but only from the page that started it.
    final shouldReturnToCaller =
        session != null &&
        returnUrl == null &&
        !wasInAppLaunched &&
        !widget.hasUnderlyingSession &&
        !session.continueOnSecondDevice;

    if (shouldReturnToCaller) {
      // iOS has no programmatic way back, so point at the status-bar back
      // link and stay put until the user leaves.
      if (Platform.isIOS) {
        if (mounted) setState(() => _showArrowBack = true);
        return;
      }
      _repo.bridgedDispatch(AndroidSendToBackgroundEvent());
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
    Haptics.error();
    return SessionErrorScreen(error: error, onTapClose: _closeSession);
  }
}
