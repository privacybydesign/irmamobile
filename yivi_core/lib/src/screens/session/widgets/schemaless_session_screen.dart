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
import "arrow_back_screen.dart";
import "disclosure_feedback_screen.dart";
import "issuance_permission.dart";
import "issuance_success_screen.dart";
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

  /// For issuance sessions with disclosures: stores the user's disclosure
  /// choices after they confirm the disclosure overview, before showing
  /// the issuance confirmation screen.
  List<DisclosureDisconSelection>? _pendingDisclosureChoices;

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

  @override
  Widget build(BuildContext context) {
    final asyncSession = ref.watch(sessionStateProvider(widget.sessionId));
    _lastSession = asyncSession;

    return asyncSession.when(
      loading: () => _buildLoadingScreen(null),
      error: (_, __) => _buildLoadingScreen(null),
      data: (session) {
        // Auto-pop when dismissed
        if (session.status == .dismissed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
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
          .requestPin => SessionPinScreen(
            sessionId: widget.sessionId,
            title: FlutterI18n.translate(context, _getAppBarTitle(session)),
          ),
          .error => _buildError(session),
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
      return SchemalessIssueDuringDisclosure(
        sessionState: session,
        onDismiss: _dismissSession,
      );
    }

    if (isIssuanceSession) {
      // if the user has yet to pick disclosures
      if (hasDisclosureChoices && _pendingDisclosureChoices == null) {
        return DisclosureChoicesOverview(
          sessionState: session,
          onDismiss: _dismissSession,
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
    return DisclosureChoicesOverview(
      sessionState: session,
      onDismiss: _dismissSession,
      onChoicesConfirmed: _grantPermission,
    );
  }

  void _dismissSession() {
    final repo = ref.read(irmaRepositoryProvider);
    repo.bridgedDispatch(
      SessionUserInteractionEvent.dismiss(sessionId: widget.sessionId),
    );
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
      if (mounted) Navigator.of(context).pop();
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

  Widget _buildError(SessionState session) {
    HapticFeedback.heavyImpact();
    return SessionErrorScreen(
      error: null,
      onTapClose: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  // Future<void> _showConfirmDialog() async {
  //   final lang = FlutterI18n.currentLocale(context)!.languageCode;
  //   final isSignature = widget.sessionState.type == SessionType.signature;
  //   final requestorName = widget.sessionState.requestor.name.translate(lang);
  //
  //   final confirmed =
  //       await showDialog<bool>(
  //         context: context,
  //         builder: (context) => IrmaConfirmationDialog(
  //           titleTranslationKey: isSignature
  //               ? "disclosure_permission.confirm_dialog.title_signature"
  //               : "disclosure_permission.confirm_dialog.title",
  //           contentTranslationKey: isSignature
  //               ? "disclosure_permission.confirm_dialog.explanation_signature"
  //               : "disclosure_permission.confirm_dialog.explanation",
  //           contentTranslationParams: {"requestorName": requestorName},
  //           confirmTranslationKey: isSignature
  //               ? "disclosure_permission.confirm_dialog.confirm_signature"
  //               : "disclosure_permission.confirm_dialog.confirm",
  //           cancelTranslationKey: isSignature
  //               ? "disclosure_permission.confirm_dialog.decline_signature"
  //               : "disclosure_permission.confirm_dialog.decline",
  //         ),
  //       ) ??
  //       false;
  //
  //   if (confirmed && mounted) {
  //     _onApprove();
  //   }
  // }
}
