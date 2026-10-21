import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/pin/yivi_pin_screen.dart";
import "package:yivi_core/src/screens/reset_pin/reset_pin_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/theme/yivi_palette.dart";

import "helpers/test_translation_loader.dart";
import "support/pump_translated.dart";

Widget _app(Widget home, {ThemeMode mode = ThemeMode.light}) => ProviderScope(
  child: IrmaTheme(
    builder: (context) => MaterialApp(
      theme: IrmaTheme.variantsOf(context).data.themeData,
      darkTheme: IrmaTheme.variantsOf(context).darkData.themeData,
      themeMode: mode,
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: TestTranslationLoader(
            basePath: "assets/locales",
            forcedLocale: const Locale("en", "US"),
          ),
        ),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: home,
    ),
  ),
);

void _phone(WidgetTester tester, [Size size = const Size(390, 844)]) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

Future<void> _enter(WidgetTester tester, String pin) async {
  for (final digit in pin.split("")) {
    await tester.tap(find.byKey(Key("number_pad_key_$digit")));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

const _warning = "This PIN is possibly not secure.";

void main() {
  group("choose PIN", () {
    Widget choose({int size = 5, void Function(String)? onSubmit}) {
      final scaffoldKey = GlobalKey<ScaffoldState>();
      return YiviPinScaffold(
        key: scaffoldKey,
        body: YiviPinScreen(
          scaffoldKey: scaffoldKey,
          instructionKey: "choose_pin.header",
          maxPinSize: size,
          checkSecurePin: true,
          onSubmit: onSubmit ?? (_) {},
        ),
      );
    }

    testWidgets("a weak PIN says so under the title, with its rules", (
      tester,
    ) async {
      _phone(tester);
      await pumpTranslated(tester, _app(choose()));
      await tester.pumpAndSettle();

      await _enter(tester, "11111");
      expect(find.textContaining(_warning), findsOneWidget);

      await tester.tapOnText(find.textRange.ofSubstring("Why?"));
      await tester.pumpAndSettle();
      expect(
        find.text("A secure PIN has the following properties:"),
        findsOneWidget,
      );
      // Pass or fail is in the label, not only in the colour.
      expect(find.bySemanticsLabel("No"), findsWidgets);
    });

    testWidgets("a weak short PIN goes on by the arrow, not by itself", (
      tester,
    ) async {
      _phone(tester);
      String? submitted;
      await pumpTranslated(
        tester,
        _app(choose(onSubmit: (pin) => submitted = pin)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("pin_next")), findsNothing);

      await _enter(tester, "11111");
      expect(submitted, isNull);
      await tester.tap(find.byKey(const Key("pin_next")));
      expect(submitted, "11111");
    });

    testWidgets("a long PIN's arrow submits from six digits", (tester) async {
      _phone(tester);
      String? submitted;
      await pumpTranslated(
        tester,
        _app(choose(size: 16, onSubmit: (pin) => submitted = pin)),
      );
      await tester.pumpAndSettle();

      await _enter(tester, "38271");
      await tester.tap(find.byKey(const Key("pin_next")));
      expect(submitted, isNull);

      await _enter(tester, "6");
      expect(find.text("6/16"), findsOneWidget);
      await tester.tap(find.byKey(const Key("pin_next")));
      expect(submitted, "382716");
    });

    testWidgets("digits use the display face", (tester) async {
      _phone(tester);
      await pumpTranslated(tester, _app(choose()));
      await tester.pumpAndSettle();

      final style = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key("number_pad_key_5")),
              matching: find.byType(Text),
            ),
          )
          .first
          .style!;
      expect(style.fontFamily, contains("Alexandria"));
    });

    for (final size in const [Size(320, 568), Size(844, 390)]) {
      testWidgets("fits $size in dark mode", (tester) async {
        _phone(tester, size);
        await pumpTranslated(tester, _app(choose(), mode: ThemeMode.dark));
        await tester.pumpAndSettle();
        await _enter(tester, "11111");
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
          YiviPalette.dark.background,
        );
      });
    }
  });

  testWidgets("forgot PIN: the reset first, cancel under it", (tester) async {
    _phone(tester);
    await pumpTranslated(tester, _app(ResetPinScreen()));
    await tester.pumpAndSettle();

    expect(find.text("Forgot your PIN?"), findsOneWidget);
    final reset = tester.getTopLeft(find.text("Start all over"));
    final cancel = tester.getTopLeft(find.text("Cancel"));
    expect(reset.dy, lessThan(cancel.dy));
  });

  testWidgets("a wrong PIN is said under the title, not in a dialog", (
    tester,
  ) async {
    _phone(tester);
    await pumpTranslated(
      tester,
      _app(
        YiviPinScaffold(
          body: YiviPinScreen(
            instructionKey: "pin.subtitle",
            maxPinSize: 5,
            onSubmit: (_) {},
            detail:
                "Wrong PIN. 2 tries left before Yivi is blocked for a while.",
            detailKind: PinDetailKind.error,
            pinError: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key("pin_screen_detail")), findsOneWidget);
    expect(find.textContaining("2 tries left"), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });
}
