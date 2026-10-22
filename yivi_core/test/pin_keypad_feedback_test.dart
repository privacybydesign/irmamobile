import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/translation_loader.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/pin/widgets/pin_keypad.dart";
import "package:yivi_core/src/theme/theme.dart";

/// Stub loader that resolves immediately with an empty map. The production
/// FileTranslationLoader reads JSON via rootBundle.loadString — real-time IO
/// that the test framework's fake clock doesn't drive, so pumpAndSettle
/// returns before Localizations rebuilds and every `find.byKey` sees 0
/// widgets. The keypad only uses translations for accessibility labels, not
/// for anything these tests assert on.
class _NoopTranslationLoader extends TranslationLoader {
  @override
  Future<Map> load() async => <String, dynamic>{};
}

void main() {
  Future<void> pumpKeypad(
    WidgetTester tester, {
    void Function(int, int)? onDigitPressed,
    void Function(int)? onDigitReleased,
    void Function(int)? onDigitCancelled,
    VoidCallback? onBackspace,
    Widget Function(Widget pad)? wrap,
    double columnGap = PinKeypad.defaultColumnGap,
  }) async {
    await tester.pumpWidget(
      IrmaTheme(
        builder: (_) => MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(translationLoader: _NoopTranslationLoader()),
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(
            body: SizedBox(
              width: PinKeypad.widthFor(columnGap) + 16,
              height: 400,
              child: (wrap ?? (pad) => pad)(
                PinKeypad(
                  onDigitPressed: onDigitPressed ?? (_, _) {},
                  onDigitReleased: onDigitReleased ?? (_) {},
                  onDigitCancelled: onDigitCancelled ?? (_) {},
                  onBackspace: onBackspace ?? () {},
                  columnGap: columnGap,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("pressing a key animates the press feedback", (tester) async {
    await pumpKeypad(tester);

    final key1 = find.byKey(const Key("number_pad_key_1"));
    expect(key1, findsOneWidget);

    double scaleOf(Finder key) {
      final t = tester.widget<Transform>(
        find.descendant(of: key, matching: find.byType(Transform)).first,
      );
      return t.transform.getColumn(0)[0]; // x scale
    }

    final before = scaleOf(key1);

    // A quick tap (down + up almost immediately) must still play the full
    // press before settling, not a stub.
    final gesture = await tester.startGesture(tester.getCenter(key1));
    await tester.pump(); // pointer down
    await gesture.up(); // released right away
    await tester.pump(const Duration(milliseconds: 90)); // press runs to peak
    final peak = scaleOf(key1);

    await tester.pumpAndSettle();
    final after = scaleOf(key1);

    expect(before, closeTo(1.0, 0.001));
    // As in the design the key shrinks a little (towards 0.92) while it
    // lights up, visibly so also on a quick tap.
    expect(peak, lessThan(0.96));
    expect(after, closeTo(1.0, 0.001)); // settled back
  });

  testWidgets("digit fires pressed on down and released on up", (tester) async {
    final pressed = <int>[];
    var released = 0;
    var cancelled = 0;
    await pumpKeypad(
      tester,
      onDigitPressed: (digit, _) => pressed.add(digit),
      onDigitReleased: (_) => released++,
      onDigitCancelled: (_) => cancelled++,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key("number_pad_key_7"))),
    );
    await tester.pump();
    expect(pressed, [7]); // dot shows on press-down
    expect(released, 0); // not committed yet

    await gesture.up();
    await tester.pumpAndSettle();
    expect(released, 1); // committed on release
    expect(cancelled, 0);
  });

  testWidgets("a cancelled press undoes the digit", (tester) async {
    final pressed = <int>[];
    var released = 0;
    var cancelled = 0;
    await pumpKeypad(
      tester,
      onDigitPressed: (digit, _) => pressed.add(digit),
      onDigitReleased: (_) => released++,
      onDigitCancelled: (_) => cancelled++,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key("number_pad_key_3"))),
    );
    await tester.pump();
    expect(pressed, [3]);

    await gesture.cancel(); // the system cancels the touch
    await tester.pumpAndSettle();
    expect(cancelled, 1); // dot removed
    expect(released, 0); // never committed
  });

  group("fast typing", () {
    testWidgets("the dot shows the moment the finger lands, also with a tap "
        "detector around the pad", (tester) async {
      final pressed = <int>[];
      await pumpKeypad(
        tester,
        onDigitPressed: (digit, _) => pressed.add(digit),
        // As on the PIN screen: something around the pad that also
        // listens for taps must not hold the keys back.
        wrap: (pad) => GestureDetector(onTap: () {}, child: pad),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key("number_pad_key_4"))),
      );
      await tester.pump();
      expect(pressed, [4]);
      await gesture.up();
    });

    testWidgets("the same key twice with two fingers is two digits", (
      tester,
    ) async {
      final pressed = <int>[];
      final released = <int>[];
      await pumpKeypad(
        tester,
        onDigitPressed: (digit, _) => pressed.add(digit),
        onDigitReleased: released.add,
      );
      final key = tester.getCenter(find.byKey(const Key("number_pad_key_1")));
      final a = await tester.startGesture(key, pointer: 1);
      final b = await tester.startGesture(key, pointer: 2);
      await a.up();
      await b.up();
      await tester.pumpAndSettle();
      expect(pressed, [1, 1]);
      expect(released, [1, 2]);
    });

    testWidgets("a finger that slides still counts", (tester) async {
      final pressed = <int>[];
      var released = 0;
      var cancelled = 0;
      await pumpKeypad(
        tester,
        onDigitPressed: (digit, _) => pressed.add(digit),
        onDigitReleased: (_) => released++,
        onDigitCancelled: (_) => cancelled++,
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key("number_pad_key_5"))),
      );
      await gesture.moveBy(const Offset(30, 20));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(pressed, [5]);
      expect(released, 1);
      expect(cancelled, 0);
    });

    testWidgets("a tap between keys goes to the nearest key", (tester) async {
      final pressed = <int>[];
      await pumpKeypad(
        tester,
        onDigitPressed: (digit, _) => pressed.add(digit),
      );
      final one = tester.getRect(find.byKey(const Key("number_pad_key_1")));
      final two = tester.getRect(find.byKey(const Key("number_pad_key_2")));
      final four = tester.getRect(find.byKey(const Key("number_pad_key_4")));
      // Just right of 1, in the gap: still 1. Just left of 2: 2.
      await tester.tapAt(Offset(one.right + 4, one.center.dy));
      await tester.tapAt(Offset(two.left - 4, two.center.dy));
      // Just under 1, in the gap between the rows: still 1.
      await tester.tapAt(Offset(one.center.dx, one.bottom + 4));
      // Just above 4: 4.
      await tester.tapAt(Offset(four.center.dx, four.top - 4));
      await tester.pumpAndSettle();
      expect(pressed, [1, 2, 1, 4]);
    });

    testWidgets("spread out wider, the gaps still go to the nearest key", (
      tester,
    ) async {
      final pressed = <int>[];
      await pumpKeypad(
        tester,
        onDigitPressed: (digit, _) => pressed.add(digit),
        wrap: (pad) => Align(alignment: Alignment.topLeft, child: pad),
        columnGap: 64,
      );
      final one = tester.getRect(find.byKey(const Key("number_pad_key_1")));
      final two = tester.getRect(find.byKey(const Key("number_pad_key_2")));
      expect(two.left - one.right, 64);
      // Left of the middle of the wide gap: 1; right of it: 2.
      await tester.tapAt(Offset(one.right + 28, one.center.dy));
      await tester.tapAt(Offset(two.left - 28, two.center.dy));
      await tester.pumpAndSettle();
      expect(pressed, [1, 2]);
    });

    testWidgets("backspace acts on release, the empty slot does nothing", (
      tester,
    ) async {
      final pressed = <int>[];
      var backspaces = 0;
      await pumpKeypad(
        tester,
        onDigitPressed: (digit, _) => pressed.add(digit),
        onBackspace: () => backspaces++,
      );
      final zero = tester.getRect(find.byKey(const Key("number_pad_key_0")));
      final gesture = await tester.startGesture(
        zero.center.translate(
          PinKeypad.keySize + PinKeypad.defaultColumnGap,
          0,
        ),
      );
      await tester.pump();
      expect(backspaces, 0);
      await gesture.up();
      expect(backspaces, 1);
      // The bottom-left slot is empty without biometrics.
      await tester.tapAt(
        zero.center.translate(
          -(PinKeypad.keySize + PinKeypad.defaultColumnGap),
          0,
        ),
      );
      await tester.pumpAndSettle();
      expect(pressed, isEmpty);
      expect(backspaces, 1);
    });
  });
}
