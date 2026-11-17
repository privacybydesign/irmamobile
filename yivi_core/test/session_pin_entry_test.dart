import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/pin/yivi_pin_screen.dart";
import "package:yivi_core/src/screens/session/widgets/session_pin_entry_screen.dart";

import "support/onboarding_v2_harness.dart";

/// A session's PIN page as the session screen drives it today: the tries
/// left and the block come in from irmago through its arguments. Phase 9
/// moves this into a provider; these must keep passing.
typedef _Args = ({int? remaining, int? blocked, bool submitting});

void main() {
  late IrmaRepository repo;
  setUp(() async {
    repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
    // A short PIN, which submits itself once full.
    await repo.preferences.longPin.set(false);
  });
  tearDown(() => repo.close());

  final submitted = <String>[];

  Future<ValueNotifier<_Args>> pump(
    WidgetTester tester, {
    _Args start = (remaining: null, blocked: null, submitting: false),
    bool inSheet = false,
  }) async {
    submitted.clear();
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final args = ValueNotifier<_Args>(start);
    await pumpHome(
      tester,
      repo: repo,
      home: ValueListenableBuilder(
        valueListenable: args,
        builder: (_, a, _) => SessionPinEntryScreen(
          title: "disclosure.title",
          remainingAttempts: a.remaining,
          blockedTimeSeconds: a.blocked,
          submitting: a.submitting,
          inSheet: inSheet,
          onPinEntered: submitted.add,
          onCancel: () {},
        ),
      ),
    );
    // Not settle: while submitting a spinner turns.
    await tester.pump(const Duration(milliseconds: 500));
    return args;
  }

  Future<void> type(WidgetTester tester, String digits) async {
    for (final d in digits.split("")) {
      await tester.sendKeyEvent(
        LogicalKeyboardKey.findKeyByKeyId(
          LogicalKeyboardKey.digit0.keyId + int.parse(d),
        )!,
      );
      await tester.pump();
    }
  }

  Finder dots(String label) => find.bySemanticsLabel(label);

  testWidgets("a wrong PIN clears the digits and says how many tries are "
      "left, the dots red", (tester) async {
    final handle = tester.ensureSemantics();
    final args = await pump(
      tester,
      start: (remaining: 3, blocked: null, submitting: false),
    );
    await type(tester, "12");
    expect(dots("2 digits entered"), findsOneWidget);
    args.value = (remaining: 2, blocked: null, submitting: false);
    await tester.pumpAndSettle();
    expect(dots("No pin code entered"), findsOneWidget);
    expect(find.textContaining("2 tries left"), findsOneWidget);
    handle.dispose();
  });

  testWidgets("a block clears the digits, counts down and turns the keypad "
      "off until it is over", (tester) async {
    final handle = tester.ensureSemantics();
    final args = await pump(
      tester,
      start: (remaining: 1, blocked: null, submitting: false),
    );
    await type(tester, "12");
    // The countdown reads the real clock: a block of two seconds.
    args.value = (remaining: 0, blocked: 2, submitting: false);
    await tester.pump();
    expect(dots("No pin code entered"), findsOneWidget);
    expect(find.textContaining("Try again in"), findsOneWidget);
    await type(tester, "1");
    expect(dots("No pin code entered"), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2100)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining("Try again in"), findsNothing);
    await type(tester, "1");
    expect(dots("1 digit entered"), findsOneWidget);
    handle.dispose();
  });

  testWidgets("today: a page first built while blocked shows no countdown "
      "(open question 5 of phase 9)", (tester) async {
    await pump(tester, start: (remaining: 0, blocked: 60, submitting: false));
    expect(find.textContaining("Try again in"), findsNothing);
  });

  testWidgets("a full PIN is sent once, also when submitted again", (
    tester,
  ) async {
    await pump(tester);
    await type(tester, "12345");
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(submitted, ["12345"]);
  });

  testWidgets("while submitting nothing is sent", (tester) async {
    await pump(
      tester,
      start: (remaining: null, blocked: null, submitting: true),
    );
    await type(tester, "12345");
    await tester.pump();
    expect(submitted, isEmpty);
  });

  testWidgets("in a sheet only the pad, no screen around it", (tester) async {
    await pump(tester, inSheet: true);
    expect(
      find.descendant(
        of: find.byType(SessionPinEntryScreen),
        matching: find.byType(Scaffold),
      ),
      findsNothing,
    );
    expect(find.byType(YiviPinScreen), findsOneWidget);
  });
}
