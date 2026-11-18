import "dart:ui" show SemanticsAction, SemanticsActionEvent;

import "package:flutter/gestures.dart";
import "package:flutter/services.dart";
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
    Widget child = const SizedBox.expand(),
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
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: IdleLockObserver(
            foregroundIdleThreshold: threshold,
            child: child,
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

  testWidgets("a key press restarts the timer, for someone using a keyboard, "
      "a D-pad or a switch", (tester) async {
    await tester.runAsync(() async {
      final repo = await pumpUnlockedApp(tester);

      for (var i = 0; i < 3; i++) {
        await wait(threshold * 0.5);
        await simulateKeyDownEvent(LogicalKeyboardKey.tab);
        await simulateKeyUpEvent(LogicalKeyboardKey.tab);
      }
      expect(await repo.getLocked().first, isFalse);

      await wait(threshold * 2);
      expect(await repo.getLocked().first, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets("an action of a screen reader restarts the timer, and still "
      "reaches the framework", (tester) async {
    await tester.runAsync(() async {
      final dispatcher = tester.binding.platformDispatcher;
      final received = <SemanticsActionEvent>[];
      final original = dispatcher.onSemanticsActionEvent;
      dispatcher.onSemanticsActionEvent = received.add;
      addTearDown(() => dispatcher.onSemanticsActionEvent = original);

      final repo = await pumpUnlockedApp(tester);

      // What TalkBack or VoiceOver sends when the user activates a control.
      const action = SemanticsActionEvent(
        type: SemanticsAction.tap,
        viewId: 0,
        nodeId: 1,
      );
      for (var i = 0; i < 3; i++) {
        await wait(threshold * 0.5);
        dispatcher.onSemanticsActionEvent!(action);
      }
      expect(await repo.getLocked().first, isFalse);
      expect(received, hasLength(3));

      await wait(threshold * 2);
      expect(await repo.getLocked().first, isTrue);

      // Unmounting hands the dispatcher back as it was found.
      await tester.pumpWidget(const SizedBox.shrink());
      expect(dispatcher.onSemanticsActionEvent, received.add);
    });
  });

  testWidgets("typing on the on-screen keyboard restarts the timer", (
    tester,
  ) async {
    await tester.runAsync(() async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      final repo = await pumpUnlockedApp(
        tester,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            style: const TextStyle(),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFF000000),
          ),
        ),
      );
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // What the on-screen keyboard sends: an edit, without any key event.
      for (var i = 0; i < 3; i++) {
        await wait(threshold * 0.5);
        tester.testTextInput.updateEditingValue(
          TextEditingValue(text: "a" * (i + 1)),
        );
      }
      expect(controller.text, "aaa");
      expect(await repo.getLocked().first, isFalse);

      await wait(threshold * 2);
      expect(await repo.getLocked().first, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets("scrolling with a mouse wheel or a trackpad restarts the "
      "timer", (tester) async {
    await tester.runAsync(() async {
      final repo = await pumpUnlockedApp(tester);

      for (var i = 0; i < 3; i++) {
        await wait(threshold * 0.5);
        tester.binding.handlePointerEvent(
          const PointerScrollEvent(
            position: Offset(50, 50),
            scrollDelta: Offset(0, 20),
          ),
        );
      }
      expect(await repo.getLocked().first, isFalse);

      await wait(threshold * 2);
      expect(await repo.getLocked().first, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets("a short trip to another app does not restart the timer", (
    tester,
  ) async {
    await tester.runAsync(() async {
      final repo = await pumpUnlockedApp(tester);

      void leaveAndComeBack() {
        for (final state in const [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
      }

      // Left and reopened three times, each well within the threshold, over a
      // period longer than the threshold, without ever using the app.
      for (var i = 0; i < 3; i++) {
        await wait(threshold * 0.5);
        leaveAndComeBack();
      }
      await wait(threshold * 0.5);

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
