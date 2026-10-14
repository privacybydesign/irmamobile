import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/adaptive_page.dart";
import "package:yivi_core/src/widgets/app_toast.dart";
import "package:yivi_core/src/widgets/code_input.dart";
import "package:yivi_core/src/widgets/irma_confirmation_dialog.dart";
import "package:yivi_core/src/widgets/irma_info_scaffold_body.dart";

import "helpers/test_translation_loader.dart";
import "support/pump_translated.dart";

/// The app around [home], in [mode], with a navigator for pushing pages.
Widget _app({
  required Widget home,
  ThemeMode mode = ThemeMode.light,
  GlobalKey<NavigatorState>? navigatorKey,
}) => IrmaTheme(
  builder: (context) => MaterialApp(
    navigatorKey: navigatorKey,
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
);

void _setWindow(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

void main() {
  group("IrmaTheme", () {
    testWidgets("hands out the dark variant under a dark theme", (
      tester,
    ) async {
      late IrmaThemeData seen;
      await pumpTranslated(
        tester,
        _app(
          mode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              seen = IrmaTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(seen.isDark, isTrue);
      expect(seen.backgroundPrimary, const Color(0xFF0E1116));
      // Text on a red fill stays white in both variants.
      expect(seen.onPrimary, Colors.white);
    });
  });

  group("IrmaConfirmationDialog", () {
    testWidgets("keeps its keys and returns the choice", (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await pumpTranslated(
        tester,
        _app(navigatorKey: navigator, home: const SizedBox()),
      );

      final result = showDialog<bool>(
        context: navigator.currentContext!,
        builder: (_) => const IrmaConfirmationDialog(
          titleTranslationKey: "ui.confirm",
          contentTranslationKey: "ui.cancel",
          destructive: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key("irma_dialog")), findsOneWidget);
      expect(find.byKey(const Key("irma_dialog_title")), findsOneWidget);
      expect(find.byKey(const Key("dialog_cancel_button")), findsOneWidget);

      await tester.tap(find.byKey(const Key("dialog_confirm_button")));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    });
  });

  group("CodeInput", () {
    testWidgets("fills the boxes and reports the complete code", (
      tester,
    ) async {
      String? completed;
      await pumpTranslated(
        tester,
        _app(
          home: Scaffold(
            body: CodeInput(
              length: 4,
              fieldKey: const Key("code"),
              onCompleted: (code) => completed = code,
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key("code")), "12a3");
      await tester.pump();
      expect(completed, isNull, reason: "letters are filtered out");
      expect(find.text("1"), findsOneWidget);
      expect(find.text("3"), findsOneWidget);

      await tester.enterText(find.byKey(const Key("code")), "1234");
      await tester.pump();
      expect(completed, "1234");
    });

    testWidgets("shows the error under the boxes", (tester) async {
      await pumpTranslated(
        tester,
        _app(
          home: const Scaffold(body: CodeInput(errorText: "Invalid code")),
        ),
      );
      expect(find.text("Invalid code"), findsOneWidget);
    });
  });

  group("IrmaInfoScaffoldBody", () {
    testWidgets("settles: the disc pulses a few times and rests", (
      tester,
    ) async {
      await pumpTranslated(
        tester,
        _app(
          home: const Scaffold(
            body: IrmaInfoScaffoldBody(
              titleTranslationKey: "ui.confirm",
              bodyTranslationKey: "ui.cancel",
              icon: Icons.warning_amber_rounded,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Confirm"), findsOneWidget);
    });
  });

  group("AdaptivePage", () {
    Future<GlobalKey<NavigatorState>> pumpHome(WidgetTester tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await pumpTranslated(
        tester,
        _app(
          navigatorKey: navigator,
          home: const Scaffold(body: Text("home")),
        ),
      );
      return navigator;
    }

    void push(
      GlobalKey<NavigatorState> navigator,
      String text, {
      PresentationMode mode = PresentationMode.sheet,
    }) {
      navigator.currentState!.push(
        AdaptivePage<void>(
          name: text,
          mode: mode,
          child: Scaffold(body: Text(text, key: Key(text))),
        ).createRoute(navigator.currentContext!),
      );
    }

    testWidgets("is a form sheet over the app on a tablet", (tester) async {
      _setWindow(tester, const Size(1180, 820));
      final navigator = await pumpHome(tester);

      push(navigator, "settings");
      await tester.pumpAndSettle();

      final sheet = tester.getRect(find.byType(ClipRSuperellipse).last);
      expect(sheet.size, const Size(540, 760));
      expect(sheet.center, const Offset(590, 410));
      // The app stays visible behind the sheet.
      expect(find.text("home"), findsOneWidget);
    });

    testWidgets("a sheet from a sheet uses the same frame", (tester) async {
      _setWindow(tester, const Size(1180, 820));
      final navigator = await pumpHome(tester);

      push(navigator, "settings");
      await tester.pumpAndSettle();
      push(navigator, "language");
      await tester.pumpAndSettle();

      final frames = tester
          .widgetList<ClipRSuperellipse>(find.byType(ClipRSuperellipse))
          .length;
      expect(frames, 2);
      expect(
        tester.getRect(find.byKey(const Key("language"))).left,
        greaterThanOrEqualTo(320),
      );
    });

    testWidgets("fills the window on a phone", (tester) async {
      _setWindow(tester, const Size(390, 844));
      final navigator = await pumpHome(tester);

      push(navigator, "settings");
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(Scaffold).last), const Size(390, 844));
    });

    testWidgets("is a centred column for full-screen states on a tablet", (
      tester,
    ) async {
      _setWindow(tester, const Size(1180, 820));
      final navigator = await pumpHome(tester);

      push(navigator, "enrollment", mode: PresentationMode.full);
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(Scaffold).last).width, 560);
      expect(find.text("home"), findsNothing);
    });
  });

  testWidgets("showAppToast shows the message", (tester) async {
    late BuildContext context;
    await pumpTranslated(
      tester,
      _app(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    showAppToast(context, "You have been logged out");
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("You have been logged out"), findsOneWidget);
  });
}
