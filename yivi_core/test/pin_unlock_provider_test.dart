import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/authentication_events.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/pin/providers/pin_countdown_provider.dart";
import "package:yivi_core/src/screens/pin/providers/pin_unlock_provider.dart";

import "support/onboarding_v2_harness.dart";

/// What the unlock notifier does with the keyshare server's answers, as it
/// is today (phase 9 must not change it).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RecordingBridge bridge;
  late IrmaRepository repo;
  late ProviderContainer container;

  /// The next PIN try gets [answer].
  void answerWith(AuthenticationEvent Function() answer) {
    bridge.respond = (event) => event is AuthenticateEvent ? answer() : null;
  }

  setUp(() async {
    bridge = RecordingBridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
    container = ProviderContainer(
      overrides: [irmaRepositoryProvider.overrideWithValue(repo)],
    );
    container.listen(pinUnlockProvider, (_, _) {});
  });
  tearDown(() async {
    container.dispose();
    await repo.close();
  });

  PinUnlockNotifier notifier() => container.read(pinUnlockProvider.notifier);
  PinUnlockState state() => container.read(pinUnlockProvider);

  test(
    "a right PIN unlocks; the long-PIN preference follows its length",
    () async {
      answerWith(AuthenticationSuccessEvent.new);
      await notifier().unlock("123456789");
      expect(state().authenticated, isTrue);
      expect(repo.preferences.longPin.value, isTrue);
      await notifier().unlock("12345");
      expect(repo.preferences.longPin.value, isFalse);
    },
  );

  test("a wrong PIN without a block: invalid, with the tries left", () async {
    answerWith(
      () => AuthenticationFailedEvent(remainingAttempts: 2, blockedDuration: 0),
    );
    await notifier().unlock("00000");
    expect(state().pinInvalid, isTrue);
    expect(state().remainingAttempts, 2);
    expect(state().blockedUntil, isNull);
    expect(state().authenticated, isFalse);
  });

  test(
    "a wrong PIN with a block: blocked until now + the block + 5 s",
    () async {
      answerWith(
        () => AuthenticationFailedEvent(
          remainingAttempts: 0,
          blockedDuration: 60,
        ),
      );
      final before = DateTime.now();
      await notifier().unlock("00000");
      final until = state().blockedUntil!;
      expect(until.difference(before).inSeconds, inInclusiveRange(64, 66));
      expect(state().pinInvalid, isTrue);
    },
  );

  test("an error: the error, not invalid", () async {
    answerWith(
      () => AuthenticationErrorEvent(
        error: SessionError(errorType: "transport", info: "offline"),
      ),
    );
    await notifier().unlock("12345");
    expect(state().error?.errorType, "transport");
    expect(state().pinInvalid, isFalse);
  });

  test("a second unlock while one runs is ignored", () async {
    final answer = Completer<void>();
    bridge.respond = (event) {
      if (event is! AuthenticateEvent) return null;
      answer.future.then((_) => bridge.deliver(AuthenticationSuccessEvent()));
      return null;
    };
    final first = notifier().unlock("12345");
    await notifier().unlock("54321");
    expect(bridge.dispatched.whereType<AuthenticateEvent>().map((e) => e.pin), [
      "12345",
    ]);
    answer.complete();
    await first;
    expect(state().authenticated, isTrue);
  });

  test(
    "a first block time from irmago seeds the block; locking keeps it",
    () async {
      final until = DateTime.now().add(const Duration(minutes: 5));
      repo.lock(unblockTime: until);
      await Future<void>.delayed(Duration.zero);
      expect(state().blockedUntil, until);
      repo.lock();
      await Future<void>.delayed(Duration.zero);
      expect(state().blockedUntil, until);
    },
  );

  test("today: after a PIN unlock, a block from locking is not seen until "
      "the next try (open question 3 of phase 9)", () async {
    answerWith(AuthenticationSuccessEvent.new);
    await notifier().unlock("12345");
    // The PIN unlock emitted a null block time: that was the one value the
    // notifier takes.
    repo.lock(unblockTime: DateTime.now().add(const Duration(minutes: 5)));
    await Future<void>.delayed(Duration.zero);
    expect(state().blockedUntil, isNull);
  });

  testWidgets("the countdown: zero without a block, else once a second", (
    tester,
  ) async {
    // In the widget test's fake time, so the seconds can be pumped.
    final c = ProviderContainer(
      overrides: [irmaRepositoryProvider.overrideWithValue(repo)],
    );
    final seen = <Duration>[];
    void follow(DateTime? until) => c.listen(
      pinCountdownProvider(until),
      (_, next) => next.whenData(seen.add),
      fireImmediately: true,
    );
    // As the lock screen does: the countdown of the notifier's block.
    c.listen(
      pinUnlockProvider.select((s) => s.blockedUntil),
      (_, until) => follow(until),
      fireImmediately: true,
    );
    await tester.pump();
    expect(seen, [Duration.zero]);

    repo.lock(unblockTime: DateTime.now().add(const Duration(hours: 1)));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    // The block, then a new value each second.
    expect(seen.length, 1 + 4);
    expect(seen.skip(1).every((d) => d > Duration.zero), isTrue);
    // The countdown's last second runs out after it is gone.
    c.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
