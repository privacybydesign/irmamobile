import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/data/session_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/translated_value.dart";

class _RecordingBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

SessionStateEvent _event(int id, SessionStatus status) => SessionStateEvent(
  sessionState: SessionState(
    id: id,
    protocol: "irma",
    type: SessionType.disclosure,
    status: status,
    requestor: TrustedParty(
      id: "requestor",
      name: TranslatedValue.fromString("Test"),
      url: null,
      parent: null,
      verified: false,
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<IrmaRepository> repository() async {
    SharedPreferences.setMockInitialValues({});
    final repo = IrmaRepository(
      client: _RecordingBridge(),
      preferences: await IrmaPreferences.fromInstance(
        mostRecentTermsUrlNl: "",
        mostRecentTermsUrlEn: "",
      ),
    );
    addTearDown(repo.close);
    return repo;
  }

  // StreamingSharedPreferences.instance is a process-wide singleton whose
  // in-memory values survive across tests, so assert on the delta from a
  // per-test baseline rather than an absolute count.

  test("each successful session increments the review counter once", () async {
    final repo = await repository();
    final base = repo.preferences.getReviewSuccessCountNow();
    final events = StreamController<Event>();
    final sessions = SessionRepository(repo: repo, eventStream: events.stream);
    addTearDown(sessions.close);
    addTearDown(events.close);

    // A session that reaches success through an intermediate state counts once.
    events.add(_event(1, SessionStatus.requestPermission));
    events.add(_event(1, SessionStatus.success));
    // A second, distinct successful session counts again.
    events.add(_event(2, SessionStatus.success));
    await Future<void>.delayed(Duration.zero);

    expect(repo.preferences.getReviewSuccessCountNow(), base + 2);
  });

  test("failed and dismissed sessions never count", () async {
    final repo = await repository();
    final base = repo.preferences.getReviewSuccessCountNow();
    final events = StreamController<Event>();
    final sessions = SessionRepository(repo: repo, eventStream: events.stream);
    addTearDown(sessions.close);
    addTearDown(events.close);

    events.add(_event(1, SessionStatus.error));
    events.add(_event(2, SessionStatus.dismissed));
    await Future<void>.delayed(Duration.zero);

    expect(repo.preferences.getReviewSuccessCountNow(), base);
  });
}
