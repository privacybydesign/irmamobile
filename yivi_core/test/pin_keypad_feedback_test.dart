import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/pin/widgets/pin_keypad.dart";
import "package:yivi_core/src/theme/theme.dart";

void main() {
  testWidgets("pressing a key animates the press feedback", (tester) async {
    await tester.pumpWidget(
      IrmaTheme(
        builder: (_) => MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: FileTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: const Locale("nl", "NL"),
              ),
            ),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 400,
              child: PinKeypad(onEnterNumber: (_) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

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
    await tester.pump(const Duration(milliseconds: 130)); // grow runs to peak
    final peak = scaleOf(key1);

    await tester.pumpAndSettle();
    final after = scaleOf(key1);

    expect(before, closeTo(1.0, 0.001));
    expect(peak, greaterThan(1.1)); // visibly grew even on a quick tap
    expect(after, closeTo(1.0, 0.001)); // settled back
  });
}
