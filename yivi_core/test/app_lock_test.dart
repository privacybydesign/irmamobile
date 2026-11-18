// What locks and unlocks the app: the lock screen's state as the bridge's
// events and the lock screen's actions move it.
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/authentication_events.dart";
import "package:yivi_core/src/models/clear_all_data_event.dart";
import "package:yivi_core/src/models/delete_keyshare_tokens_event.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/models/error_event.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/session.dart";

import "support/onboarding_v2_harness.dart";

EnrollmentStatusEvent _status({
  List<String> enrolled = const [],
  List<String> unenrolled = const [],
}) => EnrollmentStatusEvent(
  enrolledSchemeManagerIds: enrolled,
  unenrolledSchemeManagerIds: unenrolled,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingBridge bridge;
  late IrmaRepository repo;

  /// Every value the lock stream emitted, in order.
  late List<bool> lockedValues;

  setUp(() async {
    bridge = RecordingBridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
    lockedValues = [];
    repo.appLock.locked.listen(lockedValues.add);
    await pumpEventQueue();
  });
  tearDown(() => repo.close());

  Future<bool> locked() => repo.appLock.locked.first;
  Future<DateTime?> blockedUntil() => repo.appLock.blockedUntil.first;

  /// Sends [event] as Go would and lets it reach every listener.
  Future<void> deliver(Event event) async {
    bridge.deliver(event);
    await pumpEventQueue();
  }

  group("1. at the start", () {
    test("locked before anything arrives", () async {
      expect(await locked(), isTrue);
      expect(lockedValues, [true]);
    });

    test("an unenrolled default scheme unlocks", () async {
      await deliver(_status(unenrolled: ["pbdf"]));
      expect(await locked(), isFalse);
    });

    test("an enrolled default scheme stays locked", () async {
      await deliver(_status(enrolled: ["pbdf"]));
      expect(await locked(), isTrue);
    });

    test("without the default scheme at all: a fatal error, which unlocks "
        "so the error screen shows", () async {
      final fatal = repo.getFatalErrors().first;
      await deliver(_status(enrolled: ["other"]));
      expect((await fatal).fatal, isTrue);
      expect(await locked(), isFalse);
    });
  });

  group("2. lock()", () {
    test("drops the keyshare token before the lock is announced", () async {
      repo.appLock.unlockLocally();
      await pumpEventQueue();
      final order = <String>[];
      bridge.respond = (event) {
        if (event is DeleteKeyshareTokensEvent) order.add("token");
        return null;
      };
      repo.appLock.locked.skip(1).listen((value) => order.add("locked $value"));
      await pumpEventQueue();

      repo.appLock.lock();
      // The token is dropped at once, the lock reaches listeners later.
      expect(order, ["token"]);
      await pumpEventQueue();

      expect(order, ["token", "locked true"]);
    });

    test("with an unblock time: blocked until then", () async {
      final until = DateTime(2030);
      repo.appLock.lock(unblockTime: until);
      await pumpEventQueue();
      expect(await blockedUntil(), until);
    });

    test("the same value twice is announced once", () async {
      repo.appLock.unlockLocally();
      repo.appLock.lock();
      repo.appLock.lock();
      await pumpEventQueue();
      expect(lockedValues, [true, false, true]);
    });
  });

  group("3. unlock(pin)", () {
    test("a success unlocks, clears the block and remembers a short "
        "PIN", () async {
      await repo.preferences.longPin.set(true);
      repo.appLock.lock(unblockTime: DateTime(2030));
      bridge.respond = (event) =>
          event is AuthenticateEvent ? AuthenticationSuccessEvent() : null;

      final result = await repo.appLock.unlock("12345");

      expect(result, isA<AuthenticationSuccessEvent>());
      final sent = bridge.dispatched.whereType<AuthenticateEvent>().single;
      expect(sent.pin, "12345");
      expect(sent.schemeId, "pbdf");
      await pumpEventQueue();
      expect(await locked(), isFalse);
      expect(await blockedUntil(), isNull);
      expect(repo.preferences.longPin.value, isFalse);
    });

    test("a long PIN is remembered as long", () async {
      await repo.preferences.longPin.set(false);
      bridge.respond = (event) =>
          event is AuthenticateEvent ? AuthenticationSuccessEvent() : null;

      await repo.appLock.unlock("1234567");
      await pumpEventQueue();

      expect(repo.preferences.longPin.value, isTrue);
    });

    test("a wrong PIN leaves the app locked", () async {
      bridge.respond = (event) => event is AuthenticateEvent
          ? AuthenticationFailedEvent(remainingAttempts: 2, blockedDuration: 0)
          : null;

      final result = await repo.appLock.unlock("12345");
      await pumpEventQueue();

      expect(result, isA<AuthenticationFailedEvent>());
      expect(await locked(), isTrue);
    });

    test("an error leaves the app locked", () async {
      bridge.respond = (event) => event is AuthenticateEvent
          ? AuthenticationErrorEvent(
              error: SessionError(errorType: "transport", info: "offline"),
            )
          : null;

      final result = await repo.appLock.unlock("12345");
      await pumpEventQueue();

      expect(result, isA<AuthenticationErrorEvent>());
      expect(await locked(), isTrue);
    });
  });

  test("4. unlockLocally() unlocks without asking the bridge", () async {
    final before = bridge.dispatched.length;
    repo.appLock.unlockLocally();
    await pumpEventQueue();

    expect(await locked(), isFalse);
    expect(bridge.dispatched.length, before);
  });

  group("5. errors and a reset", () {
    test("a fatal error unlocks, so the error screen shows", () async {
      await deliver(ErrorEvent(exception: "boom", stack: "", fatal: true));
      expect(await locked(), isFalse);
    });

    test("clearing all data unlocks and clears the block", () async {
      repo.appLock.lock(unblockTime: DateTime(2030));
      repo.bridgedDispatch(ClearAllDataEvent());
      await pumpEventQueue();

      expect(await locked(), isFalse);
      expect(await blockedUntil(), isNull);
    });
  });

  group("6. a logout skips the next automatic biometric scan and is "
      "confirmed", () {
    test("once each, after a logout, which locks", () async {
      repo.appLock.unlockLocally();
      repo.appLock.logOut();
      await pumpEventQueue();
      expect(await locked(), isTrue);
      expect(
        bridge.dispatched.whereType<DeleteKeyshareTokensEvent>(),
        isNotEmpty,
      );
      expect(repo.appLock.consumeLogoutAutoScanSuppressed(), isTrue);
      expect(repo.appLock.consumeLogoutAutoScanSuppressed(), isFalse);
      expect(repo.appLock.consumeLogoutConfirmation(), isTrue);
      expect(repo.appLock.consumeLogoutConfirmation(), isFalse);
    });

    test("not after a plain lock", () async {
      repo.appLock.lock();
      expect(repo.appLock.consumeLogoutAutoScanSuppressed(), isFalse);
      expect(repo.appLock.consumeLogoutConfirmation(), isFalse);
    });
  });
}
