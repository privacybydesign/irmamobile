import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/util/idle_lock_observer.dart";

class _FakeBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}

  void receive(Event event) => addEvent(event);
}

/// A phone put down unlocked with Yivi open must not stay open for as long as
/// the screen stays on.
///
/// These tests run on the real clock, with a short threshold: locking reads the
/// repository's streams, which do not complete under the test's fake clock.
void main() {
  const threshold = Duration(milliseconds: 400);

  Future<void> wait(Duration duration) => Future<void>.delayed(duration);

  Future<IrmaRepository> pumpUnlockedApp(
    WidgetTester tester, {
    bool enrolled = true,
  }) async {
    final bridge = _FakeBridge();
    SharedPreferences.setMockInitialValues({});
    final repo = IrmaRepository(
      client: bridge,
      preferences: await IrmaPreferences.fromInstance(
        mostRecentTermsUrlNl: "",
        mostRecentTermsUrlEn: "",
      ),
    );
    bridge.receive(
      EnrollmentStatusEvent(
        enrolledSchemeManagerIds: enrolled ? ["pbdf"] : [],
        unenrolledSchemeManagerIds: enrolled ? [] : ["pbdf"],
      ),
    );
    await wait(Duration.zero);
    repo.unlockAppLocally();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [irmaRepositoryProvider.overrideWithValue(repo)],
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: IdleLockObserver(
            foregroundIdleThreshold: threshold,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
    return repo;
  }

  void touch(WidgetTester tester) {
    const position = Offset(50, 50);
    tester.binding.handlePointerEvent(
      const PointerDownEvent(pointer: 1, position: position),
    );
    tester.binding.handlePointerEvent(
      const PointerUpEvent(pointer: 1, position: position),
    );
  }

  testWidgets("locks when the app is left open and untouched", (tester) async {
    await tester.runAsync(() async {
      final repo = await pumpUnlockedApp(tester);
      expect(await repo.getLocked().first, isFalse);

      await wait(threshold * 2);

      expect(await repo.getLocked().first, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets("a touch anywhere in the app restarts the timer", (tester) async {
    await tester.runAsync(() async {
      final repo = await pumpUnlockedApp(tester);

      // Touched three times, each well within the threshold, over a period
      // longer than the threshold.
      for (var i = 0; i < 3; i++) {
        await wait(threshold * 0.5);
        touch(tester);
      }
      expect(await repo.getLocked().first, isFalse);

      await wait(threshold * 2);
      expect(await repo.getLocked().first, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets("locks again after an unlock that did not touch the app, such "
      "as with biometrics", (tester) async {
    await tester.runAsync(() async {
      final repo = await pumpUnlockedApp(tester);
      await wait(threshold * 2);
      expect(await repo.getLocked().first, isTrue);

      repo.unlockAppLocally();
      expect(await repo.getLocked().first, isFalse);
      await wait(threshold * 2);

      expect(await repo.getLocked().first, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets("leaves an app without a wallet alone: there is nothing to "
      "lock", (tester) async {
    await tester.runAsync(() async {
      final repo = await pumpUnlockedApp(tester, enrolled: false);

      await wait(threshold * 2);

      expect(await repo.getLocked().first, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
