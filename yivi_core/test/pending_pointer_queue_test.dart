// The queue of the session or e-mail link waiting to be started, and the
// launch handshake the lock screen waits for (ADR 0004).

import "package:flutter/foundation.dart" show FlutterError;
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/email_code_pointer.dart";
import "package:yivi_core/src/models/handle_url_event.dart";
import "package:yivi_core/src/models/native_events.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_events.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/models/session_user_interaction.dart";

import "support/onboarding_v2_harness.dart";

const _sessionUrl = "https://example.com/irma/session/abc";
const _sessionLink =
    'https://open.yivi.app/-/session#{"u":"$_sessionUrl","irmaqr":"disclosing"}';

SessionPointer _pointer() => Pointer.fromString(_sessionLink) as SessionPointer;

/// Lets an event reach every listener, also the ones that wait once.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingBridge bridge;
  late IrmaRepository repo;
  late List<MethodCall> urlLauncherCalls;

  setUp(() async {
    // A link that opens the app closes the in-app browser.
    urlLauncherCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("plugins.flutter.io/url_launcher"),
          (call) async {
            urlLauncherCalls.add(call);
            return null;
          },
        );
    bridge = RecordingBridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
  });
  tearDown(() async {
    await repo.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("plugins.flutter.io/url_launcher"),
          null,
        );
  });

  test("7. a cold start from a link: the pointer is queued by the time the "
      "launch handshake is over", () async {
    final pendingWhenResolved = <Pointer?>[];
    repo.getStartupUrlResolved().listen((resolved) {
      if (resolved) pendingWhenResolved.add(repo.pendingPointer);
    });
    expect(await repo.getStartupUrlResolved().first, isFalse);

    // Native sends the launch URL, then the acknowledgement as a message of
    // its own.
    bridge.deliver(HandleURLEvent(url: _sessionLink));
    await _settle();
    bridge.deliver(AppReadyAckEvent());
    await _settle();

    expect(pendingWhenResolved, hasLength(1));
    expect(pendingWhenResolved.single, isA<SessionPointer>());
    expect((pendingWhenResolved.single! as SessionPointer).u, _sessionUrl);
    expect(urlLauncherCalls.map((c) => c.method), contains("closeWebView"));
  });

  test(
    "7. a cold start without a link: resolved with nothing queued",
    () async {
      bridge.deliver(AppReadyAckEvent());
      await _settle();

      expect(await repo.getStartupUrlResolved().first, isTrue);
      expect(repo.pendingPointer, isNull);
    },
  );

  test("8. starting a session clears the queue in the same delivery that "
      "marks it in flight", () async {
    repo.setPendingPointer(_pointer());
    await _settle();

    // Whenever either signal changes, a session must still be known to be
    // waiting: the lock screen's biometric backstop reads both.
    final gaps = <String>[];
    void check(String what) {
      if (repo.pendingPointer == null && !repo.hasInFlightSession) {
        gaps.add(what);
      }
    }

    final subs = [
      repo.getPendingPointer().listen((_) => check("pointer")),
      repo.getHasInFlightSession().listen((_) => check("in flight")),
    ];
    addTearDown(() => Future.wait(subs.map((s) => s.cancel())));
    await _settle();

    repo.bridgedDispatch(NewSessionEvent(sessionId: 1, request: _pointer()));
    check("dispatched");
    // Both happen a microtask later, together.
    expect(repo.pendingPointer, isNotNull);
    expect(repo.hasInFlightSession, isFalse);

    await Future<void>.microtask(() {});
    expect(repo.pendingPointer, isNull);
    expect(repo.hasInFlightSession, isTrue);

    await _settle();
    expect(gaps, isEmpty);
    expect(bridge.dispatched.whereType<NewSessionEvent>(), hasLength(1));
  });

  group("9. what a link puts in the queue", () {
    test("an e-mail code link queues the code", () async {
      bridge.deliver(
        HandleURLEvent(url: "https://open.yivi.app/-/email#code=abc123"),
      );
      await _settle();

      final pending = repo.pendingPointer;
      expect(pending, isA<EmailCodePointer>());
      expect((pending! as EmailCodePointer).code, "ABC123");
      expect((pending as EmailCodePointer).email, isNull);
    });

    test("the issuer's login callback queues nothing and goes to its "
        "session", () async {
      bridge.deliver(
        SessionStateEvent(
          sessionState: SessionState(
            id: 7,
            protocol: "openid4vci",
            type: SessionType.issuance,
            status: SessionStatus.requestAuthorizationCode,
            requestor: TrustedParty(
              id: "issuer",
              name: "Issuer",
              url: null,
              parent: null,
              verified: true,
            ),
            continueOnSecondDevice: false,
            openID4VCIState: "s-1",
          ),
        ),
      );
      await _settle();

      const callback = "app.yivi.open://auth-callback?state=s-1&code=c";
      bridge.deliver(HandleURLEvent(url: callback));
      await _settle();

      expect(repo.pendingPointer, isNull);
      final sent = bridge.dispatched
          .whereType<SessionUserInteractionEvent>()
          .single;
      expect(sent.sessionId, 7);
      expect(sent.type, UserInteractionType.authorizationCode);
      expect(sent.payload!["callback_url"], callback);
    });

    test("a link that is no pointer queues nothing and is reported", () async {
      final reported = <Object>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) => reported.add(details.exception);
      addTearDown(() => FlutterError.onError = previous);

      bridge.deliver(HandleURLEvent(url: "https://example.com/nothing"));
      await _settle();

      expect(repo.pendingPointer, isNull);
      expect(reported.single, isA<MissingPointer>());
    });
  });

  test("10. a test session from a URL is queued as a second-device "
      "pointer", () async {
    repo.startTestSessionFromUrl(_sessionLink);

    final pending = repo.pendingPointer;
    expect(pending, isA<SessionPointer>());
    expect((pending! as SessionPointer).u, _sessionUrl);
    expect((pending as SessionPointer).continueOnSecondDevice, isTrue);
  });
}
