import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../data/irma_repository.dart";
import "../../models/native_events.dart";
import "../../models/return_url.dart";
import "../../models/schemaless/session_state.dart";
import "../../models/schemaless/session_user_interaction.dart";
import "../../models/session.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/session_state_provider.dart";
import "../../sentry/sentry.dart";
import "../../util/language.dart";
import "../../util/navigation.dart";
import "../../widgets/loading_indicator.dart";
import "../error/session_error_screen.dart";
import "../error/tx_code_lockout_screen.dart";
import "call_info_screen.dart";
import "widgets/arrow_back_screen.dart";
import "widgets/disclosure_choices_overview.dart";
import "widgets/disclosure_feedback_screen.dart";
import "widgets/disclosure_permission_close_dialog.dart";
import "widgets/disclosure_permission_confirm_dialog.dart";
import "widgets/disclosure_permission_introduction_screen.dart";
import "widgets/issuance_permission.dart";
import "widgets/issuance_success_screen.dart";
import "widgets/issue_during_disclosure_screen.dart";
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
  AsyncValue<SessionState>? _lastSession;

  /// For issuance sessions with disclosures: stores the user's disclosure
  /// choices after they confirm the disclosure overview, before showing
  /// the issuance confirmation screen.
  List<DisclosureDisconSelection>? _pendingDisclosureChoices;

  bool _hasLongPin = false;

  /// Whether the disclosure introduction screen should be shown.
  /// Null means we haven't loaded the preference yet.
  bool? _showIntroduction;

  /// Whether issuance-during-disclosure was shown (steps were present at some point).
  bool _hadIssueDuringDisclosure = false;

  /// Whether the user has acknowledged the issuance-during-disclosure completion.
  bool _issueDuringDisclosureAcknowledged = false;

  /// True after the OID4VCI side effect (auto-grant or browser launch) has
  /// fired for the current session, so we don't fire it again on rebuilds or
  /// when the user returns from a cancelled browser flow.
  bool _autoTriggeredForOpenID4VCI = false;

  /// Tracks the most recent non-null `remainingTxCodeAttempts`. When the
  /// session subsequently transitions to [SessionStatus.error] with this
  /// equal to 1, we know the cause is a tx_code lockout and can show the
  /// dedicated screen instead of the generic error.
  int? _lastSeenRemainingTxCodeAttempts;

  /// True after dispatching openURLExternally / openURLinAppBrowser, so
  /// post-frame rebuilds of the success screen don't re-fire the side effect.
  bool _returnUrlSideEffectFired = false;

  /// Set when a return-URL launch threw. Renders the error screen until the
  /// user closes it; the close handler then skips the silent reopen.
  SessionError? _returnUrlError;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(irmaRepositoryProvider);
    _repo.preferences.getLongPin().first.then((value) {
      if (mounted) setState(() => _hasLongPin = value);
    });
    _repo.preferences.getCompletedDisclosurePermissionIntro().first.then((
      introCompleted,
    ) {
      if (mounted) setState(() => _showIntroduction = !introCompleted);
    });
  }

  @override
  void dispose() {
    // Dismiss unless we've already observed a terminal state. A null
    // `_lastSession?.value` means Go hasn't emitted any state yet — that
    // window exists because SessionScreen is now pushed before the first
    // SessionStateEvent — and backing out during it must still dismiss the
    // Go-side session.
    // We use cached values because ref is unsafe to use during dispose.
    final status = _lastSession?.value?.status;
    final isTerminal =
        status == SessionStatus.success ||
        status == SessionStatus.error ||
        status == SessionStatus.dismissed;
    if (!isTerminal) {
      _repo.bridgedDispatch(
        SessionUserInteractionEvent.dismiss(sessionId: widget.sessionId),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncSession = ref.watch(sessionStateProvider(widget.sessionId));
    final isAwaiting = ref.watch(
      sessionAwaitingInteractionProvider(widget.sessionId),
    );
    _lastSession = asyncSession;

    // Track the latest non-null remainingTxCodeAttempts so that, if the
    // session subsequently errors out, we can detect the tx_code-lockout
    // case and show the dedicated screen.
    ref.listen(sessionStateProvider(widget.sessionId), (prev, next) {
      final attempts = next.value?.remainingTxCodeAttempts;
      if (attempts != null) {
        _lastSeenRemainingTxCodeAttempts = attempts;
      }
    });

    // Auto-trigger OID4VCI side effects on first entry into the relevant
    // states. The flag prevents re-firing on rebuilds (e.g. when the user
    // returns from a cancelled browser session).
    ref.listen(sessionStateProvider(widget.sessionId), (prev, next) {
      final session = next.value;
      if (session == null || _autoTriggeredForOpenID4VCI) return;

      if (session.status == SessionStatus.requestPreAuthorizedCode &&
          session.transactionCodeParameters == null) {
        _autoTriggeredForOpenID4VCI = true;
        _grantPreAuthorizedCode(session, transactionCode: null);
      } else if (session.status == SessionStatus.requestAuthorizationCode) {
        _autoTriggeredForOpenID4VCI = true;
        _repo.authenticateOpenID4VCI(session.authorizationRequestUrl!);
      }
    });

    // Show loading while waiting for a state update after user interaction,
    // except when on the PIN screen — it handles its own loading overlay
    // and must stay mounted so didUpdateWidget can detect wrong PIN attempts.
    if (isAwaiting && asyncSession.value?.status != .requestPin) {
      return _buildLoadingScreen(asyncSession.value);
    }

    return asyncSession.when(
      loading: () => _buildLoadingScreen(null),
      error: (err, __) =>
          _buildError(SessionError(errorType: "unknown", info: err.toString())),
      data: (session) {
        // Auto-pop when dismissed — pop back to the previous screen
        // (scanner, home, or underlying session).
        if (session.status == .dismissed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              if (widget.hasUnderlyingSession) {
                context.popToUnderlyingSession();
              } else {
                Navigator.of(context).pop();
              }
            }
          });
          return _buildLoadingScreen(session);
        }

        // Show success screen
        if (session.status == .success) {
          HapticFeedback.mediumImpact();
          return _buildSuccess(session);
        }

        return switch (session.status) {
          .showPairingCode => PairingRequired(
            pairingCode: session.pairingCode ?? "",
            onDismiss: _dismissSession,
          ),
          .requestPermission => _buildRequestPermission(session),
          .requestPin => SessionPinEntryScreen(
            title: _getAppBarTitle(session),
            remainingAttempts: session.remainingPinAttempts,
            blockedTimeSeconds: session.pinBlockedTimeSeconds,
            submitting: isAwaiting,
            maxPinSize: _hasLongPin ? 16 : 5,
            onPinEntered: (pin) => _submitPin(pin),
            onCancel: _dismissSession,
          ),
          .error =>
            _lastSeenRemainingTxCodeAttempts == 1
                ? TxCodeLockoutScreen(onTapClose: _closeSession)
                : _buildError(
                    session.error ??
                        SessionError(errorType: "unknown", info: ""),
                  ),
          // dismissed and success are handled above
          .dismissed || .success => _buildLoadingScreen(session),
          .requestPreAuthorizedCode ||
          .requestAuthorizationCode => _buildOpenIdRequestPermission(session),
        };
      },
    );
  }

  Widget _buildRequestPermission(SessionState session) {
    // Show introduction screen for disclosure/signature sessions if not yet completed.
    if (_showIntroduction == true && session.type != SessionType.issuance) {
      return DisclosurePermissionIntroductionScreen(
        onContinue: () {
          _repo.preferences.setCompletedDisclosurePermissionIntro(true);
          setState(() => _showIntroduction = false);
        },
        onDismiss: _showDismissDialog,
      );
    }

    final plan = session.disclosurePlan;
    final hasDisclosureChoices =
        plan?.disclosureChoicesOverview?.isNotEmpty ?? false;

    final needsIssueBeforeDisclosure =
        !hasDisclosureChoices &&
        plan?.issueDuringDisclosure != null &&
        plan!.issueDuringDisclosure!.steps.isNotEmpty;

    // Track that issuance-during-disclosure was shown.
    if (needsIssueBeforeDisclosure) {
      _hadIssueDuringDisclosure = true;
    }

    final isIssuanceSession =
        session.type == .issuance && session.offeredCredentials != null;

    // Show issuance screen while steps are pending, or keep showing it
    // in completed state until the user acknowledges by tapping "Next step".
    if (needsIssueBeforeDisclosure ||
        (_hadIssueDuringDisclosure && !_issueDuringDisclosureAcknowledged)) {
      return IssueDuringDisclosureScreen(
        sessionId: widget.sessionId,
        onDismiss: _showDismissDialog,
        onClose: _dismissSession,
        onCompleted: () {
          setState(() => _issueDuringDisclosureAcknowledged = true);
        },
      );
    }

    if (isIssuanceSession) {
      // if the user has yet to pick disclosures
      if (hasDisclosureChoices && _pendingDisclosureChoices == null) {
        return DisclosureChoicesOverview(
          sessionState: session,
          onDismiss: _showDismissDialog,
          onChoicesConfirmed: (choices) {
            setState(() => _pendingDisclosureChoices = choices);
          },
        );
      }

      return IssuancePermission(
        issuedCredentials: session.offeredCredentials!,
        onDismiss: _dismissSession,
        onGivePermission: () {
          _grantPermission(_pendingDisclosureChoices ?? []);
        },
      );
    }

    // Pure disclosure or signature session where issuance is no longer required
    final hadIssueDuringDisclosure = plan?.issueDuringDisclosure != null;
    return DisclosureChoicesOverview(
      sessionState: session,
      hasIssueDuringDisclosure: hadIssueDuringDisclosure,
      onDismiss: _showDismissDialog,
      onChoicesConfirmed: (choices) {
        _showShareConfirmDialog(session, choices);
      },
    );
  }

  Widget _buildOpenIdRequestPermission(SessionState session) {
    if (session.status == SessionStatus.requestPreAuthorizedCode) {
      if (session.transactionCodeParameters != null) {
        return OpenID4VCIPreAuthTxCodeScreen(
          sessionId: widget.sessionId,
          issuedCredentials: session.offeredCredentialTypes!,
          transactionCodeParameters: session.transactionCodeParameters!,
          onSubmit: (code) =>
              _grantPreAuthorizedCode(session, transactionCode: code),
          onDismiss: _dismissSession,
        );
      }
      // No tx code: auto-grant has already fired in ref.listen above; show a
      // loading screen until the next state arrives.
      return _buildLoadingScreen(session);
    }

    // requestAuthorizationCode: browser auto-opened via ref.listen. This
    // screen is shown when the user returns to the app without completing.
    return OpenID4VCIAuthCodePendingScreen(
      issuer: session.offeredCredentialTypes!.first.issuer,
      onOpenBrowser: () =>
          _repo.authenticateOpenID4VCI(session.authorizationRequestUrl!),
      onDismiss: _dismissSession,
    );
  }

  void _submitPin(String pin) {
    _repo.bridgedDispatch(
      SessionUserInteractionEvent.pin(
        sessionId: widget.sessionId,
        pin: pin,
        proceed: true,
      ),
    );
  }

  void _dismissSession() {
    final repo = ref.read(irmaRepositoryProvider);
    repo.bridgedDispatch(
      SessionUserInteractionEvent.dismiss(sessionId: widget.sessionId),
    );
  }

  Future<void> _showDismissDialog() async {
    await DisclosurePermissionCloseDialog.show(
      context,
      onConfirm: _dismissSession,
    );
  }

  Future<void> _showShareConfirmDialog(
    SessionState session,
    List<DisclosureDisconSelection> choices,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => DisclosurePermissionConfirmDialog(
            requestor: session.requestor,
            isSignatureSession: session.type == SessionType.signature,
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      _grantPermission(choices);
    }
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
      body: Center(child: LoadingIndicator()),
      onDismiss: _dismissSession,
      appBarTitle: session != null
          ? _getAppBarTitle(session)
          : "disclosure.title",
    );
  }

  void _grantPermission(List<DisclosureDisconSelection> disclosureChoices) {
    final repo = ref.read(irmaRepositoryProvider);
    repo.bridgedDispatch(
      SessionUserInteractionEvent.permission(
        sessionId: widget.sessionId,
        granted: true,
        disclosureChoices: disclosureChoices,
      ),
    );
  }

  Widget _buildSuccess(SessionState session) {
    void pop() {
      if (mounted) {
        context.popToUnderlyingSessionOrHome(
          hasUnderlyingSession: widget.hasUnderlyingSession,
        );
      }
    }

    // If this is an issuance session spawned during a disclosure flow,
    // skip the success screen and pop back to the underlying disclosure session.
    if (widget.hasUnderlyingSession && session.type == .issuance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.popToUnderlyingSession();
      });
      return _buildLoadingScreen(session);
    }

    final returnUrl = session.parsedClientReturnUrl;
    if (returnUrl != null) {
      if (returnUrl.isPhoneNumber) {
        return CallInfoScreen(
          otherParty: getTranslation(context, session.requestor.name),
          onContinue: () => _openReturnUrl(
            returnUrl,
            alwaysExternal: true,
            popOnSuccess: true,
          ),
          onCancel: _closeSession,
        );
      }
      if (_returnUrlError != null) {
        return _buildError(_returnUrlError!);
      }
      if (!_returnUrlSideEffectFired) {
        _returnUrlSideEffectFired = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (returnUrl.isInApp) {
            // Pop first so the in-app browser overlays home / underlying.
            _popToUnderlyingOrHome();
            await _openReturnUrl(
              returnUrl,
              alwaysExternal: false,
              popOnSuccess: false,
            );
          } else {
            // Open first; only pop if the launch succeeded so a failure can
            // surface the error screen on top of the success screen.
            await _openReturnUrl(
              returnUrl,
              alwaysExternal: true,
              popOnSuccess: true,
            );
          }
        });
      }
      return _buildLoadingScreen(session);
    }

    // Multi-device session: result lives on the other device, so just confirm
    // success here.
    if (session.continueOnSecondDevice) {
      if (session.type == .issuance) {
        return IssuanceSuccessScreen(onDismiss: (_) => pop());
      }
      return DisclosureFeedbackScreen(
        feedbackType: .success,
        isSignatureSession: session.type == .signature,
        otherParty: getTranslation(context, session.requestor.name),
        onDismiss: (_) => pop(),
      );
    }

    // Same-device session: hand the user back to the calling app. iOS lacks a
    // programmatic way to do that, so we show ArrowBack telling them to tap
    // the back link in the status bar. On Android we move the task to the
    // background so the OS surfaces the previous app automatically.
    if (Platform.isIOS) {
      return ArrowBack(
        type: session.type == .issuance
            ? .issuance
            : session.type == .signature
            ? .signature
            : .disclosure,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo.bridgedDispatch(AndroidSendToBackgroundEvent());
      pop();
    });
    return _buildLoadingScreen(session);
  }

  Future<void> _closeSession() async {
    final session = _lastSession?.value;
    final returnUrl = session?.parsedClientReturnUrl;
    final shouldSilentReopen =
        returnUrl != null &&
        !returnUrl.isPhoneNumber &&
        session?.error?.errorType != "clientReturnUrl" &&
        _returnUrlError?.errorType != "clientReturnUrl";

    if (shouldSilentReopen) {
      try {
        await _repo.openURLExternally(returnUrl.toString());
      } catch (e, st) {
        // The user is on the way out — don't surface a second error screen.
        reportError(e, st);
      }
    }

    if (mounted) {
      context.popToUnderlyingSessionOrHome(
        hasUnderlyingSession: widget.hasUnderlyingSession,
      );
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
    HapticFeedback.heavyImpact();
    return SessionErrorScreen(error: error, onTapClose: _closeSession);
  }

  void _grantPreAuthorizedCode(
    SessionState session, {
    required String? transactionCode,
  }) {
    _repo.bridgedDispatch(
      SessionUserInteractionEvent.preAuthorizedCodePermission(
        sessionId: session.id,
        transactionCode: transactionCode,
        proceed: true,
      ),
    );
  }
}
