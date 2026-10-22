import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/schemaless/session_user_interaction.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_events.dart";
import "package:yivi_core/src/screens/enrollment/email/enrollment_email_link.dart";

import "support/onboarding_v2_harness.dart";

SessionStateEvent _state(int id, SessionStatus status) => SessionStateEvent(
  sessionState: SessionState(
    id: id,
    protocol: "irma",
    type: SessionType.issuance,
    status: status,
    requestor: TrustedParty(
      id: "email-issuer",
      name: "Yivi",
      url: null,
      parent: null,
      verified: true,
    ),
  ),
);

SessionPointer _pointer() => SessionPointer(
  u: "https://example.com/session",
  irmaqr: "issuing",
  protocol: Protocol.irma,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingBridge bridge;
  late IrmaRepository repo;

  setUp(() async {
    bridge = RecordingBridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  /// Answers the app the way irmago would: the session asks for permission,
  /// then for the PIN, and ends as [end] once the PIN is given.
  void irmago({
    SessionStatus end = SessionStatus.success,
    bool askPinTwice = false,
  }) {
    var pins = 0;
    bridge.respond = (Event event) {
      if (event is NewSessionEvent) {
        return _state(event.sessionId, SessionStatus.requestPermission);
      }
      if (event is SessionUserInteractionEvent) {
        if (event.type == UserInteractionType.permission) {
          return _state(event.sessionId, SessionStatus.requestPin);
        }
        if (event.type == UserInteractionType.enteredPin) {
          pins++;
          if (askPinTwice && pins == 1) {
            return _state(event.sessionId, SessionStatus.requestPin);
          }
          return _state(event.sessionId, end);
        }
      }
      return null;
    };
  }

  List<SessionUserInteractionEvent> answers() =>
      bridge.dispatched.whereType<SessionUserInteractionEvent>().toList();

  test("grants the session and gives it the enrollment's PIN", () async {
    irmago();
    await runOwnSession(repo, _pointer(), pin: "12345");

    final sent = answers();
    expect(sent.map((e) => e.type), [
      UserInteractionType.permission,
      UserInteractionType.enteredPin,
    ]);
    expect(sent.first.payload!["granted"], isTrue);
    expect(sent.last.payload!["pin"], "12345");
    expect(sent.last.payload!["proceed"], isTrue);
  });

  test("fails when the session ends in an error", () async {
    irmago(end: SessionStatus.error);

    await expectLater(
      runOwnSession(repo, _pointer(), pin: "12345"),
      throwsA(isA<OwnSessionFailed>()),
    );
  });

  test("gives the PIN once: a second prompt dismisses the session", () async {
    irmago(askPinTwice: true);

    await expectLater(
      runOwnSession(repo, _pointer(), pin: "12345"),
      throwsA(isA<OwnSessionFailed>()),
    );
    expect(answers().last.type, UserInteractionType.dismiss);
    expect(
      answers().where((e) => e.type == UserInteractionType.enteredPin),
      hasLength(1),
    );
  });

  test("dismisses a session that does not answer in time", () async {
    bridge.respond = (_) => null;

    await expectLater(
      runOwnSession(
        repo,
        _pointer(),
        pin: "12345",
        timeout: const Duration(milliseconds: 50),
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(answers().single.type, UserInteractionType.dismiss);
  });
}
