import "dart:async";

import "../../../data/irma_repository.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../models/schemaless/session_user_interaction.dart";
import "../../../models/session.dart";
import "../../../models/session_events.dart";
import "../../session/models/disclosure_view_model.dart";

/// A session the enrollment's e-mail step started for itself did not finish.
class OwnSessionFailed implements Exception {
  final SessionStatus status;

  OwnSessionFailed(this.status);

  @override
  String toString() => "The session ended with $status";
}

/// Runs a session the e-mail step started for itself, without its screens:
/// the e-mail issuance of the code the user typed, and the disclosure that
/// links the address in MijnYivi. The user asked for both by tapping Send
/// code (the page says the address is linked in MijnYivi), so the session's
/// permission is granted, and its PIN prompt answered with the PIN chosen in
/// this enrollment, so the user is not asked for it again a minute later.
///
/// Anything else the session asks (a pairing code, a second PIN prompt after
/// a wrong PIN) dismisses it, and so does [timeout].
Future<void> runOwnSession(
  IrmaRepository repo,
  SessionPointer pointer, {
  required String pin,
  Duration timeout = const Duration(minutes: 2),
}) async {
  final sessionId = repo.allocateSessionId();
  final done = Completer<void>();
  var permissionGiven = false;
  var pinGiven = false;

  void dismiss(SessionStatus status) {
    repo.bridgedDispatch(
      SessionUserInteractionEvent.dismiss(sessionId: sessionId),
    );
    if (!done.isCompleted) done.completeError(OwnSessionFailed(status));
  }

  final subscription = repo.getSessionState(sessionId).listen((session) {
    if (done.isCompleted) return;
    switch (session.status) {
      case SessionStatus.requestPermission:
        if (permissionGiven) return;
        permissionGiven = true;
        repo.bridgedDispatch(
          SessionUserInteractionEvent.permission(
            sessionId: sessionId,
            granted: true,
            disclosureChoices: disclosureChoicesFor(
              session.disclosurePlan?.disclosureChoicesOverview ?? const [],
              const {},
            ),
          ),
        );
      case SessionStatus.requestPin:
        if (pinGiven) return dismiss(session.status);
        pinGiven = true;
        repo.bridgedDispatch(
          SessionUserInteractionEvent.pin(
            sessionId: sessionId,
            proceed: true,
            pin: pin,
          ),
        );
      case SessionStatus.success:
        done.complete();
      case SessionStatus.error || SessionStatus.dismissed:
        done.completeError(OwnSessionFailed(session.status));
      default:
        dismiss(session.status);
    }
  });

  repo.bridgedDispatch(NewSessionEvent(sessionId: sessionId, request: pointer));
  try {
    await done.future.timeout(timeout);
  } on TimeoutException {
    dismiss(SessionStatus.dismissed);
    rethrow;
  } finally {
    await subscription.cancel();
  }
}
