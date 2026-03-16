import "package:flutter/material.dart";

import "../models/session.dart";
import "../models/session_events.dart";
import "../providers/irma_repository_provider.dart";
import "navigation.dart";

/// First handles the issue wizard if one is present, and subsequently the session is handled.
/// If no wizard is specified, only the session will be performed.
/// If no session is specified, the user will be returned to the HomeScreen after completing the wizard.
/// If pushReplacement is true, then the current screen is being replaced with the handler screen.
Future<void> handlePointer(
  BuildContext context,
  Pointer pointer, {
  bool pushReplacement = false,
}) async {
  try {
    await pointer.validate(irmaRepository: IrmaRepositoryProvider.of(context));
  } catch (e) {
    if (!context.mounted) {
      return;
    }
    final message = "error starting session or wizard: $e";
    if (pushReplacement) {
      context.pushReplacementErrorScreen(message: message);
    } else {
      context.pushErrorScreen(message: message);
    }
    return;
  }

  if (pointer is SessionPointer && context.mounted) {
    _startSession(context, pointer, pushReplacement: pushReplacement);
  }
}

/// Dispatches a NewSessionEvent to Go and pushes the session screen
/// when Go responds with a [SessionStateEvent] containing the session ID.
void _startSession(
  BuildContext context,
  SessionPointer sessionPointer, {
  bool pushReplacement = false,
}) {
  final repo = IrmaRepositoryProvider.of(context);
  repo.bridgedDispatch(NewSessionEvent(request: sessionPointer));

  // Listen for the next new session ID and push the session screen.
  repo.getNewSessionIds().first.then((sessionId) async {
    if (!context.mounted) return;
    final hasUnderlying = await repo.hasActiveSessions(
      excludeSessionId: sessionId,
    );
    if (!context.mounted) return;
    final params = SessionRouteParams(
      sessionId: sessionId,
      hasUnderlyingSession: hasUnderlying,
    );
    if (pushReplacement) {
      context.pushReplacementSessionScreen(params);
    } else {
      context.pushSessionScreen(params);
    }
  });
}
