import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../data/irma_repository.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../models/schemaless/session_user_interaction.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../widgets/loading_indicator.dart";
import "../../error/session_error_screen.dart";
import "../../pin/session_pin_screen.dart";
import "issuance_permission.dart";
import "pairing_required.dart";
import "schemaless_disclosure_overview.dart";
import "schemaless_issue_during_disclosure.dart";
import "session_scaffold.dart";

/// Displays the current [SessionState] for a given session ID.
///
/// This widget is purely presentational — it does not modify the session state.
/// Navigation is driven externally: the [SchemalessSessionListener] pushes this
/// screen when a new session appears, and this screen pops itself when the
/// session status becomes [SessionStatus.dismissed].
class SchemalessSessionScreen extends StatefulWidget {
  final int sessionId;

  const SchemalessSessionScreen({super.key, required this.sessionId});

  @override
  State<SchemalessSessionScreen> createState() =>
      _SchemalessSessionScreenState();
}

class _SchemalessSessionScreenState extends State<SchemalessSessionScreen> {
  late IrmaRepository _repo;
  late Stream<SessionState> _sessionStateStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = IrmaRepositoryProvider.of(context);
    _sessionStateStream = _repo.getSessionState(widget.sessionId);
  }

  @override
  void dispose() {
    // If the screen is being disposed while the session is still active, dismiss it.
    _sessionStateStream.first.then((session) {
      if (session.status != SessionStatus.success &&
          session.status != SessionStatus.error &&
          session.status != SessionStatus.dismissed) {
        _repo.bridgedDispatch(
          SessionUserInteractionEvent.dismiss(sessionId: widget.sessionId),
        );
      }
    });
    super.dispose();
  }

  void _dismissSession() {
    _repo.bridgedDispatch(
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
    // Pure issuance session
    if (session.type == SessionType.issuance &&
        session.offeredCredentials != null) {
      return IssuancePermission(
        issuedCredentials: session.offeredCredentials!,
        onDismiss: _dismissSession,
        onGivePermission: () => _repo.bridgedDispatch(
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
    if (plan?.issueDuringDislosure != null &&
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

  @override
  Widget build(BuildContext context) => StreamBuilder<SessionState>(
    stream: _sessionStateStream,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return _buildLoadingScreen(null);
      }

      final session = snapshot.data!;

      // Auto-pop when dismissed
      if (session.status == SessionStatus.dismissed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
        return _buildLoadingScreen(session);
      }

      // Auto-navigate home on success
      if (session.status == SessionStatus.success) {
        HapticFeedback.mediumImpact();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
        return _buildLoadingScreen(session);
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

  Widget _buildError(SessionState session) {
    HapticFeedback.heavyImpact();
    return SessionErrorScreen(
      error: null,
      onTapClose: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }
}
