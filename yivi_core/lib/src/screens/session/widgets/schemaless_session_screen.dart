import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../data/irma_repository.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../models/schemaless/session_user_interaction.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../util/language.dart";
import "../../../widgets/loading_indicator.dart";
import "../../error/session_error_screen.dart";
import "../../pin/session_pin_screen.dart";
import "disclosure_feedback_screen.dart";
import "issuance_permission.dart";
import "issuance_success_screen.dart";
import "pairing_required.dart";
import "schemaless_disclosure_overview.dart";
import "schemaless_issue_during_disclosure.dart";
import "session_scaffold.dart";
import "success_graphic.dart";

/// Displays the current [SessionState] for a given session ID.
///
/// This widget is purely presentational — it does not modify the session state.
/// Navigation is driven externally: the [SchemalessSessionListener] pushes this
/// screen when a new session appears, and this screen pops itself when the
/// session status becomes [SessionStatus.dismissed].
class SchemalessSessionScreen extends ConsumerStatefulWidget {
  final int sessionId;

  const SchemalessSessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SchemalessSessionScreen> createState() =>
      _SchemalessSessionScreenState();
}

class _SchemalessSessionScreenState
    extends ConsumerState<SchemalessSessionScreen> {
  late final IrmaRepository _repo;
  AsyncValue<SessionState>? _lastSession;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(irmaRepositoryProvider);
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

  void _dismissSession() {
    final repo = ref.read(irmaRepositoryProvider);
    repo.bridgedDispatch(
      SessionUserInteractionEvent.dismiss(sessionId: widget.sessionId),
    );
  }

  String _getAppBarTitle(SessionState session) {
    return switch (session.type) {
      SessionType.issuance => "issuance.title",
      SessionType.signature => "disclosure.title",
      SessionType.disclosure => "disclosure.title",
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

  Widget _buildRequestPermission(SessionState session) {
    final repo = ref.read(irmaRepositoryProvider);

    // Pure issuance session
    if (session.type == SessionType.issuance &&
        session.offeredCredentials != null) {
      return IssuancePermission(
        issuedCredentials: session.offeredCredentials!,
        onDismiss: _dismissSession,
        onGivePermission: () => repo.bridgedDispatch(
          SessionUserInteractionEvent.permission(
            sessionId: widget.sessionId,
            granted: true,
            disclosureChoices: [],
          ),
        ),
      );
    }

    final plan = session.disclosurePlan;

    // Show issuance-during-disclosure if there are incomplete steps
    // and the user can't make disclosure choices yet
    final hasDisclosureChoices =
        plan?.disclosureChoicesOverview?.isNotEmpty ?? false;
    if (!hasDisclosureChoices &&
        plan?.issueDuringDislosure != null &&
        plan!.issueDuringDislosure!.steps.isNotEmpty) {
      return SchemalessIssueDuringDisclosure(
        sessionState: session,
        onDismiss: _dismissSession,
      );
    }

    return SchemalessDisclosureOverview(
      sessionState: session,
      onDismiss: _dismissSession,
    );
  }

  Widget _buildSuccess(SessionState session) {
    void pop() {
      if (mounted) Navigator.of(context).pop();
    }

    // Second-device flow: show a success screen with a dismiss button.
    if (session.continueOnSecondDevice) {
      if (session.type == SessionType.issuance) {
        return IssuanceSuccessScreen(onDismiss: (_) => pop());
      }

      return DisclosureFeedbackScreen(
        feedbackType: DisclosureFeedbackType.success,
        isSignatureSession: session.type == SessionType.signature,
        otherParty: getTranslation(context, session.requestor.name),
        onDismiss: (_) => pop(),
      );
    }

    // Same-device flow: show the pointing man graphic, then auto-pop.
    return _SameDeviceSuccessScreen(onComplete: pop);
  }

  Widget _buildError(SessionState session) {
    HapticFeedback.heavyImpact();
    return SessionErrorScreen(
      error: null,
      onTapClose: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncSession = ref.watch(sessionStateProvider(widget.sessionId));
    _lastSession = asyncSession;

    return asyncSession.when(
      loading: () => _buildLoadingScreen(null),
      error: (_, __) => _buildLoadingScreen(null),
      data: (session) {
        // Auto-pop when dismissed
        if (session.status == SessionStatus.dismissed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
          return _buildLoadingScreen(session);
        }

        // Show success screen
        if (session.status == SessionStatus.success) {
          HapticFeedback.mediumImpact();
          return _buildSuccess(session);
        }

        return switch (session.status) {
          SessionStatus.showPairingCode => PairingRequired(
            pairingCode: session.pairingCode ?? "",
            onDismiss: _dismissSession,
          ),
          SessionStatus.requestPermission => _buildRequestPermission(session),
          SessionStatus.requestPin => SessionPinScreen(
            sessionId: widget.sessionId,
            title: FlutterI18n.translate(context, _getAppBarTitle(session)),
          ),
          SessionStatus.error => _buildError(session),
          // dismissed and success are handled above
          SessionStatus.dismissed ||
          SessionStatus.success => _buildLoadingScreen(session),
        };
      },
    );
  }
}

/// Brief success screen for same-device flows.
/// Shows the success graphic and auto-pops after a short delay.
class _SameDeviceSuccessScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const _SameDeviceSuccessScreen({required this.onComplete});

  @override
  State<_SameDeviceSuccessScreen> createState() =>
      _SameDeviceSuccessScreenState();
}

class _SameDeviceSuccessScreenState extends State<_SameDeviceSuccessScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: SuccessGraphic()));
  }
}
