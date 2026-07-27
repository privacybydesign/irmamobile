import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/schemaless/session_user_interaction.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_events.dart";

class _RecordingBridge extends IrmaBridge {
  final dispatched = <Event>[];

  @override
  void dispatch(Event event) => dispatched.add(event);
}

Future<IrmaRepository> _repo(_RecordingBridge bridge) async {
  SharedPreferences.setMockInitialValues({});
  return IrmaRepository(
    client: bridge,
    preferences: await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Regression for the lock-screen ✕: it is shown while a session is in flight
  // (any non-terminal status), so cancelling must dismiss the same set — not
  // only `requestPermission` sessions. A session between its start and Go's
  // first `requestPermission` reply is in flight but not yet active, and the ✕
  // must still cancel it.
  test("dismissAllInFlightSessions cancels a session that has not reached "
      "requestPermission", () async {
    final bridge = _RecordingBridge();
    final repo = await _repo(bridge);
    addTearDown(repo.close);

    // Start a session, but deliver no SessionStateEvent: it is in flight yet
    // never reached `requestPermission`.
    final pointer =
        Pointer.fromString(
              '{"u":"https://example.com/irma/session/abc","irmaqr":"disclosing"}',
            )
            as SessionPointer;
    repo.dispatch(NewSessionEvent(sessionId: 1, request: pointer));
    await pumpEventQueue();

    expect(repo.hasInFlightSession, isTrue);
    // Not `requestPermission`, so the old requestPermission-only cancel path
    // would have dismissed nothing here.
    expect(repo.hasActiveSessions(), isFalse);

    repo.dismissAllInFlightSessions();

    final dismissedIds = bridge.dispatched
        .whereType<SessionUserInteractionEvent>()
        .where((e) => e.type == UserInteractionType.dismiss)
        .map((e) => e.sessionId);
    expect(dismissedIds, contains(1));
  });
}
