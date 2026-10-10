import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../models/email_code_pointer.dart";
import "../models/session.dart";
import "../models/session_events.dart";
import "../providers/email_issuance_provider.dart";
import "../providers/email_linking_provider.dart";
import "../providers/irma_repository_provider.dart";
import "navigation.dart";

/// First handles the issue wizard if one is present, and subsequently the session is handled.
/// If no wizard is specified, only the session will be performed.
/// If no session is specified, the user will be returned to the HomeScreen after completing the wizard.
/// If pushReplacement is true, then the current screen is being replaced with the handler screen.
/// Returns the id of the session that was started, if any.
Future<int?> handlePointer(
  BuildContext context,
  Pointer pointer, {
  bool pushReplacement = false,
}) async {
  if (pointer is EmailCodePointer) {
    _showEmailLinkScreen(context, pointer);
    return null;
  }

  try {
    await pointer.validate(irmaRepository: IrmaRepositoryProvider.of(context));
  } catch (e) {
    if (!context.mounted) {
      return null;
    }
    final message = "error starting session or wizard: $e";
    if (pushReplacement) {
      context.pushReplacementErrorScreen(message: message);
    } else {
      context.pushErrorScreen(message: message);
    }
    return null;
  }

  if (pointer is SessionPointer && context.mounted) {
    return _startSession(context, pointer, pushReplacement: pushReplacement);
  }
  return null;
}

/// Opens the e-mail linking screens for the link in the verification e-mail.
/// If they are already open, the code screen picks the link up from the
/// provider instead.
void _showEmailLinkScreen(BuildContext context, EmailCodePointer link) {
  final container = ProviderScope.containerOf(context, listen: false);
  final alreadyOpen = container.exists(emailIssuanceProvider);

  container.read(emailLinkingProvider.notifier).receiveLink(link);
  if (!alreadyOpen) {
    context.pushEmailIssuanceScreen(purpose: EmailIssuancePurpose.linkKeyshare);
  }
}

/// Dispatches a NewSessionEvent to Go and pushes [SessionScreen] synchronously.
/// The session id is allocated Dart-side so the screen can mount immediately
/// and render its existing "no state yet" loading branch while Go contacts
/// the relying party.
int _startSession(
  BuildContext context,
  SessionPointer sessionPointer, {
  bool pushReplacement = false,
}) {
  final repo = IrmaRepositoryProvider.of(context);

  final sessionId = repo.allocateSessionId();
  // Any session active at this moment is "underlying" — ours does not exist on
  // the Go side yet, so we don't need to exclude it.
  final hasUnderlying = repo.hasActiveSessions();

  repo.bridgedDispatch(
    NewSessionEvent(sessionId: sessionId, request: sessionPointer),
  );

  final params = SessionRouteParams(
    sessionId: sessionId,
    hasUnderlyingSession: hasUnderlying,
  );
  if (pushReplacement) {
    context.pushReplacementSessionScreen(params);
  } else {
    context.pushSessionScreen(params);
  }
  return sessionId;
}
