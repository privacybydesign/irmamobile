import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/pin/yivi_pin_screen.dart";
import "package:yivi_core/src/screens/reset_pin/reset_pin_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/theme/yivi_palette.dart";
import "package:yivi_core/src/widgets/glass/glass_dialog.dart";
import "package:yivi_core/src/widgets/pin_common/pin_wrong_attempts.dart";
import "package:yivi_core/src/widgets/pin_common/pin_wrong_blocked.dart";

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

const _infoButton = "PIN possibly not secure";

void main() {
  group("choose PIN", () {
    Widget choose() {
      final scaffoldKey = GlobalKey<ScaffoldState>();
      return YiviPinScaffold(
        key: scaffoldKey,
        body: YiviPinScreen(
          scaffoldKey: scaffoldKey,
          instructionKey: "choose_pin.header",
          maxPinSize: 5,
          checkSecurePin: true,
          onSubmit: (_) {},
        ),
      );
    }

    testWidgets("a weak PIN shows the warning pill and its rules", (
      tester,
    ) async {
      _phone(tester);
      await pumpTranslated(tester, _app(choose()));
      await tester.pumpAndSettle();

      await _enter(tester, "11111");
      final warning = find.text(_infoButton);
      expect(warning, findsOneWidget);

      await tester.tap(warning);
      await tester.pumpAndSettle();
      expect(
        find.text("A secure PIN has the following properties:"),
        findsOneWidget,
      );
      // Pass or fail is in the label, not only in the colour.
      expect(find.bySemanticsLabel("No"), findsWidgets);
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

  group("dialogs carry an icon", () {
    for (final (name, dialog) in [
      (
        "wrong PIN",
        PinWrongAttemptsDialog(attemptsRemaining: 2, onClose: () {}),
      ),
      ("blocked", const PinWrongBlockedDialog(blocked: 60)),
    ]) {
      testWidgets(name, (tester) async {
        _phone(tester);
        await pumpTranslated(tester, _app(Scaffold(body: dialog)));
        await tester.pumpAndSettle();
        expect(find.byType(ToneDisc), findsOneWidget);
      });
    }
  });
}
