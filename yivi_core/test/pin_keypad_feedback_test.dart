import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
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
    void Function(int)? onDigitPressed,
    VoidCallback? onDigitReleased,
    VoidCallback? onDigitCancelled,
    VoidCallback? onBackspace,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildYiviThemeData(),
        localizationsDelegates: [
          FlutterI18nDelegate(translationLoader: _NoopTranslationLoader()),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 400,
            child: PinKeypad(
              onDigitPressed: onDigitPressed ?? (_) {},
              onDigitReleased: onDigitReleased ?? () {},
              onDigitCancelled: onDigitCancelled ?? () {},
              onBackspace: onBackspace ?? () {},
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
    // grow before settling, not a stub.
    final gesture = await tester.startGesture(tester.getCenter(key1));
    await tester.pump(); // pointer down
    await gesture.up(); // released right away
    await tester.pump(const Duration(milliseconds: 90)); // grow runs to peak
    final peak = scaleOf(key1);

    await tester.pumpAndSettle();
    final after = scaleOf(key1);

    expect(before, closeTo(1.0, 0.001));
    expect(peak, greaterThan(1.1)); // visibly grew even on a quick tap
    expect(after, closeTo(1.0, 0.001)); // settled back
  });

  testWidgets("digit fires pressed on down and released on up", (tester) async {
    final pressed = <int>[];
    var released = 0;
    var cancelled = 0;
    await pumpKeypad(
      tester,
      onDigitPressed: pressed.add,
      onDigitReleased: () => released++,
      onDigitCancelled: () => cancelled++,
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
      onDigitPressed: pressed.add,
      onDigitReleased: () => released++,
      onDigitCancelled: () => cancelled++,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key("number_pad_key_3"))),
    );
    await tester.pump();
    expect(pressed, [3]);

    await gesture.cancel(); // finger slides off / arena lost
    await tester.pumpAndSettle();
    expect(cancelled, 1); // dot removed
    expect(released, 0); // never committed
  });
}
