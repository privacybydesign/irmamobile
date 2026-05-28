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

/// Dispatches a NewSessionEvent to Go and pushes [SessionScreen] synchronously.
/// The session id is allocated Dart-side so the screen can mount immediately
/// and render its existing "no state yet" loading branch while Go contacts
/// the relying party.
void _startSession(
  BuildContext context,
  SessionPointer sessionPointer, {
  bool pushReplacement = false,
}) async {
  final repo = IrmaRepositoryProvider.of(context);

  final sessionId = repo.allocateSessionId();
  // Any session active at this moment is "underlying" — ours does not exist on
  // the Go side yet, so we don't need to exclude it.
  final hasUnderlying = await repo.hasActiveSessions();
  if (!context.mounted) return;

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
}
