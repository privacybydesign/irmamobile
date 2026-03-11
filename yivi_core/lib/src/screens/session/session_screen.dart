import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../data/irma_repository.dart";
import "../../models/schemaless/session_state.dart";
import "../../models/schemaless/session_user_interaction.dart";
import "../../models/session.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/session_state_provider.dart";
import "../../util/language.dart";
import "../../util/navigation.dart";
import "../../widgets/irma_confirmation_dialog.dart";
import "../../widgets/loading_indicator.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/irma_error_scaffold_body.dart";
import "widgets/arrow_back_screen.dart";
import "widgets/disclosure_choices_overview.dart";
import "widgets/disclosure_feedback_screen.dart";
import "widgets/issuance_permission.dart";
import "widgets/issuance_success_screen.dart";
import "widgets/issue_during_disclosure_screen.dart";
import "widgets/pairing_required.dart";
import "widgets/session_pin_entry_screen.dart";
import "widgets/session_scaffold.dart";

/// Displays the current [SessionState] for a given session ID.
///
/// This widget is purely presentational — it does not modify the session state.
/// Navigation is driven externally: the [SchemalessSessionListener] pushes this
/// screen when a new session appears, and this screen pops itself when the
/// session status becomes [SessionStatus.dismissed].
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

  bool _pinSubmitting = false;
  bool _hasLongPin = false;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(irmaRepositoryProvider);
    _repo.preferences.getLongPin().first.then((value) {
      if (mounted) setState(() => _hasLongPin = value);
    });
  }

  @override
  void dispose() {
    // If the screen is being disposed while the session is still active, dismiss it.
    // We use cached values because ref is unsafe to use during dispose.
    final session = _lastSession?.value;
    if (session != null &&
        session.status != SessionStatus.success &&
        session.status != SessionStatus.error &&
        session.status != SessionStatus.dismissed) {
      _repo.bridgedDispatch(
        SessionUserInteractionEvent.dismiss(sessionId: widget.sessionId),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncSession = ref.watch(sessionStateProvider(widget.sessionId));
    _lastSession = asyncSession;

    return asyncSession.when(
      loading: () => _buildLoadingScreen(null),
      error: (err, __) =>
          _buildError(SessionError(errorType: "unknown", info: err.toString())),
      data: (session) {
        // Reset pin submitting state when session state updates
        if (_pinSubmitting) _pinSubmitting = false;

        // Auto-pop when dismissed
        if (session.status == .dismissed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.popToUnderlyingSessionOrHome(
                hasUnderlyingSession: widget.hasUnderlyingSession,
              );
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
            submitting: _pinSubmitting,
            maxPinSize: _hasLongPin ? 16 : 5,
            onPinEntered: (pin) => _submitPin(pin),
            onCancel: _dismissSession,
            onBlocked: () {
              context.goHomeScreen();
            },
          ),
          .error => _buildError(
            session.error ?? SessionError(errorType: "unknown", info: ""),
          ),
          // dismissed and success are handled above
          .dismissed || .success => _buildLoadingScreen(session),
        };
      },
    );
  }

  Widget _buildRequestPermission(SessionState session) {
    final plan = session.disclosurePlan;
    final hasDisclosureChoices =
        plan?.disclosureChoicesOverview?.isNotEmpty ?? false;

    final needsIssueBeforeDisclosure =
        !hasDisclosureChoices &&
        plan?.issueDuringDislosure != null &&
        plan!.issueDuringDislosure!.steps.isNotEmpty;

    final isIssuanceSession =
        session.type == .issuance && session.offeredCredentials != null;

    // in any case where issuance is required before being able to complete
    // this session (same for any session type)
    if (needsIssueBeforeDisclosure) {
      return IssueDuringDisclosureScreen(
        sessionId: widget.sessionId,
        onDismiss: _showDismissDialog,
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
        onDismiss: _showDismissDialog,
        onGivePermission: () {
          _grantPermission(_pendingDisclosureChoices ?? []);
        },
      );
    }

    // Pure disclosure or signature session where issuance is no longer required
    final hadIssueDuringDisclosure = plan?.issueDuringDislosure != null;
    return DisclosureChoicesOverview(
      sessionState: session,
      hasIssueDuringDisclosure: hadIssueDuringDisclosure,
      onDismiss: _showDismissDialog,
      onChoicesConfirmed: (choices) {
        _showShareConfirmDialog(session, choices);
      },
    );
  }

  void _submitPin(String pin) {
    setState(() => _pinSubmitting = true);
    _repo.bridgedDispatch(
      SessionUserInteractionEvent.pin(
        sessionId: widget.sessionId,
        pin: pin,
        proceed: true,
      ),
    );
    // _pinSubmitting will be reset when the session state changes
    // (rebuilds with a different status or updated remainingPinAttempts).
  }

  void _dismissSession() {
    final repo = ref.read(irmaRepositoryProvider);
    repo.bridgedDispatch(
      SessionUserInteractionEvent.dismiss(sessionId: widget.sessionId),
    );
  }

  Future<void> _showDismissDialog() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => const IrmaConfirmationDialog(
            titleTranslationKey:
                "disclosure_permission.confirm_close_dialog.title",
            contentTranslationKey:
                "disclosure_permission.confirm_close_dialog.explanation",
            confirmTranslationKey:
                "disclosure_permission.confirm_close_dialog.confirm",
            cancelTranslationKey:
                "disclosure_permission.confirm_close_dialog.decline",
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      _dismissSession();
    }
  }

  Future<void> _showShareConfirmDialog(
    SessionState session,
    List<DisclosureDisconSelection> choices,
  ) async {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final isSignature = session.type == SessionType.signature;
    final requestorName = session.requestor.name.translate(lang);

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => IrmaConfirmationDialog(
            titleTranslationKey: isSignature
                ? "disclosure_permission.confirm_dialog.title_signature"
                : "disclosure_permission.confirm_dialog.title",
            contentTranslationKey: isSignature
                ? "disclosure_permission.confirm_dialog.explanation_signature"
                : "disclosure_permission.confirm_dialog.explanation",
            contentTranslationParams: {"requestorName": requestorName},
            confirmTranslationKey: isSignature
                ? "disclosure_permission.confirm_dialog.confirm_signature"
                : "disclosure_permission.confirm_dialog.confirm",
            cancelTranslationKey: isSignature
                ? "disclosure_permission.confirm_dialog.decline_signature"
                : "disclosure_permission.confirm_dialog.decline",
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

    // Second-device flow: show a success screen with a dismiss button.
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

    final ArrowBackType t = switch (session.type) {
      .disclosure => .disclosure,
      .issuance => .issuance,
      .signature => .signature,
    };

    return ArrowBack(type: t);
  }

  void _closeSession() {
    if (mounted) {
      context.popToUnderlyingSessionOrHome(
        hasUnderlyingSession: widget.hasUnderlyingSession,
      );
    }
  }

  Widget _buildError(SessionError error) {
    HapticFeedback.heavyImpact();
    return SessionScaffold(
      appBarTitle: "error.details_title",
      onDismiss: _closeSession,
      body: IrmaErrorScaffoldBody(
        type: ErrorType.general,
        details: error.toString(),
        reportable: error.reportable,
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, "error.button_ok"),
        onPrimaryPressed: _closeSession,
      ),
    );
  }
}
