import "dart:io";
import "dart:ui" as ui;

import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/screens/session/widgets/calm_success_feedback.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_feedback_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/screens/session/widgets/success_graphic.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/action_feedback.dart";
import "package:yivi_core/src/widgets/irma_icon_button.dart";
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";

import "support/pump_translated.dart";

/// Whether a test runs with `FeatureFlag.calmSuccess` on or off.
enum _Flag { on, off }

/// Which kind of disclosure session the feedback screen is shown for.
enum _Session { disclosure, signature }

/// The size of the boards J1 and J2, in logical pixels.
const _phone = Size(390, 844);

/// The bytes of one pixel in the raw RGBA image of a screenshot.
const _bytesPerPixel = 4;

/// A screenshot of the test app, at 1 logical px per pixel.
class _Screenshot {
  final ByteData _bytes;
  final int _width;

  _Screenshot(this._bytes, this._width);

  Color at(num x, num y) {
    final offset = (y.floor() * _width + x.floor()) * _bytesPerPixel;
    return Color.fromARGB(
      _bytes.getUint8(offset + 3),
      _bytes.getUint8(offset),
      _bytes.getUint8(offset + 1),
      _bytes.getUint8(offset + 2),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final theme = IrmaThemeData();
  final boundaryKey = GlobalKey();
  late IrmaPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    // Tests draw text in the Ahem font unless the app's own font is loaded,
    // and every glyph of Ahem is a square, which wraps the lines differently.
    final openSans = FontLoader("Open Sans");
    for (final weight in ["Regular", "SemiBold", "Bold"]) {
      openSans.addFont(
        File(
          "fonts/open-sans/OpenSans-$weight.ttf",
        ).readAsBytes().then(ByteData.sublistView),
      );
    }
    await openSans.load();
  });

  // StreamingSharedPreferences.instance is a process-wide singleton, so
  // clearAll() is what gives each test a clean store.
  setUp(() async {
    prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await prefs.clearAll();
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required _Flag flag,
    String language = "en",
    Size size = _phone,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await prefs.setFeatureFlag(FeatureFlag.calmSuccess, flag == _Flag.on);

    await pumpTranslated(
      tester,
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
        child: IrmaTheme(
          builder: (context) => MaterialApp(
            theme: IrmaTheme.of(context).themeData,
            builder: (context, child) => LegacyMaterialBridge(child: child!),
            localizationsDelegates: [
              FlutterI18nDelegate(
                translationLoader: FileTranslationLoader(
                  basePath: "assets/locales",
                  forcedLocale: Locale(language),
                ),
              ),
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: RepaintBoundary(key: boundaryKey, child: screen),
          ),
        ),
      ),
    );

    // The flag arrives through a stream, so the screen is first built with it
    // off and rebuilt by the next pump.
    await tester.pump();
    await tester.pump();
  }

  Future<_Screenshot> screenshot(WidgetTester tester) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    final image = await tester.runAsync(() => boundary.toImage());
    final bytes = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    return _Screenshot(bytes!, image!.width);
  }

  String graphicAsset(WidgetTester tester) {
    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    return (picture.bytesLoader as SvgAssetLoader).assetName;
  }

  TextStyle styleOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!;

  Widget issuance({VoidCallback? onDismiss}) =>
      IssuanceSuccessScreen(onDismiss: (_) => onDismiss?.call());

  Widget disclosure(
    DisclosureFeedbackType type, {
    _Session session = _Session.disclosure,
    String otherParty = "Gemeente",
    VoidCallback? onDismiss,
  }) => DisclosureFeedbackScreen(
    feedbackType: type,
    otherParty: otherParty,
    isSignatureSession: session == _Session.signature,
    onDismiss: (_) => onDismiss?.call(),
  );

  group("SuccessGraphic", () {
    final classic = RegExp(r"assets/success/success_[1-5]\.svg$");
    final calmAsset = RegExp(r"assets/success/calm_[1-2]\.svg$");

    testWidgets("flag off shows one of the five cheering people", (
      tester,
    ) async {
      await pumpScreen(tester, const SuccessGraphic(), flag: _Flag.off);

      expect(graphicAsset(tester), matches(classic));
    });

    testWidgets("flag on shows one of the two calm people", (tester) async {
      await pumpScreen(tester, const SuccessGraphic(), flag: _Flag.on);

      expect(graphicAsset(tester), matches(calmAsset));
    });

    testWidgets("both calm illustrations get picked", (tester) async {
      await pumpScreen(
        tester,
        SingleChildScrollView(
          child: Column(
            children: [for (var i = 0; i < 30; i++) SuccessGraphic()],
          ),
        ),
        flag: _Flag.on,
      );

      final assets = tester
          .widgetList<SvgPicture>(find.byType(SvgPicture))
          .map((picture) => (picture.bytesLoader as SvgAssetLoader).assetName);

      expect(assets.toSet(), hasLength(2));
    });
  });

  group("IssuanceSuccessScreen", () {
    testWidgets("flag off keeps the current screen and copy", (tester) async {
      await pumpScreen(tester, issuance(), flag: _Flag.off);

      expect(find.byType(ActionFeedback), findsOneWidget);
      expect(find.byType(CalmSuccessFeedback), findsNothing);
      expect(find.text("Success"), findsWidgets);
      expect(
        find.text("The data has been successfully added to Yivi"),
        findsOneWidget,
      );
      expect(find.text("Added"), findsNothing);
    });

    testWidgets("flag off in Dutch has the spelling fixed", (tester) async {
      await pumpScreen(tester, issuance(), flag: _Flag.off, language: "nl");

      expect(
        find.text("De gegevens zijn succesvol aan Yivi toegevoegd."),
        findsOneWidget,
      );
    });

    testWidgets("flag on has the copy of J1 in Dutch", (tester) async {
      await pumpScreen(tester, issuance(), flag: _Flag.on, language: "nl");

      expect(find.byType(CalmSuccessFeedback), findsOneWidget);
      expect(find.text("Toegevoegd"), findsOneWidget);
      expect(find.text("De gegevens staan in je Yivi-app"), findsOneWidget);
      expect(find.text("Je vindt ze terug onder Gegevens."), findsOneWidget);
      expect(find.text("Gelukt"), findsNothing);
    });

    testWidgets("flag on has the copy of J1 in English", (tester) async {
      await pumpScreen(tester, issuance(), flag: _Flag.on);

      expect(find.text("Added"), findsOneWidget);
      expect(find.text("The data is in your Yivi app"), findsOneWidget);
      expect(find.text("You can find it under Data."), findsOneWidget);
    });

    testWidgets("flag on has the copy of J1 in German", (tester) async {
      await pumpScreen(tester, issuance(), flag: _Flag.on, language: "de");

      expect(find.text("Hinzugefügt"), findsOneWidget);
      expect(find.text("Die Daten sind in Ihrer Yivi-App"), findsOneWidget);
      expect(find.text("Sie finden sie unter Daten."), findsOneWidget);
    });
  });

  group("DisclosureFeedbackScreen", () {
    testWidgets("flag off keeps the current screen and copy", (tester) async {
      await pumpScreen(
        tester,
        disclosure(DisclosureFeedbackType.success),
        flag: _Flag.off,
      );

      expect(find.byType(ActionFeedback), findsOneWidget);
      expect(find.byType(CalmSuccessFeedback), findsNothing);
      expect(find.text("Your data is disclosed to Gemeente"), findsOneWidget);
      expect(find.text("Shared"), findsNothing);
    });

    testWidgets("flag on has the copy of J2 in Dutch", (tester) async {
      await pumpScreen(
        tester,
        disclosure(DisclosureFeedbackType.success),
        flag: _Flag.on,
        language: "nl",
      );

      expect(find.byType(CalmSuccessFeedback), findsOneWidget);
      expect(find.text("Gedeeld"), findsOneWidget);
      expect(
        find.text("Je gegevens zijn gedeeld met Gemeente"),
        findsOneWidget,
      );
      expect(find.text("Je kunt terug naar de website."), findsOneWidget);
      expect(find.text("Gelukt"), findsNothing);
    });

    testWidgets("flag on has the copy of J2 in English", (tester) async {
      await pumpScreen(
        tester,
        disclosure(DisclosureFeedbackType.success),
        flag: _Flag.on,
      );

      expect(find.text("Shared"), findsOneWidget);
      expect(
        find.text("Your data has been shared with Gemeente"),
        findsOneWidget,
      );
      expect(find.text("You can go back to the website."), findsOneWidget);
    });

    testWidgets("flag on has the copy of J2 in German", (tester) async {
      await pumpScreen(
        tester,
        disclosure(DisclosureFeedbackType.success),
        flag: _Flag.on,
        language: "de",
      );

      expect(find.text("Geteilt"), findsOneWidget);
      expect(
        find.text("Ihre Daten wurden mit Gemeente geteilt"),
        findsOneWidget,
      );
      expect(find.text("Sie können zurück zur Website."), findsOneWidget);
    });

    testWidgets("flag on keeps the screen of a signature session", (
      tester,
    ) async {
      await pumpScreen(
        tester,
        disclosure(DisclosureFeedbackType.success, session: _Session.signature),
        flag: _Flag.on,
      );

      expect(find.byType(CalmSuccessFeedback), findsNothing);
      expect(find.text("You signed the request of Gemeente"), findsOneWidget);
      expect(find.text("Shared"), findsNothing);
    });

    testWidgets("flag on keeps the screen of a cancelled session", (
      tester,
    ) async {
      await pumpScreen(
        tester,
        disclosure(DisclosureFeedbackType.canceled),
        flag: _Flag.on,
      );

      expect(find.byType(CalmSuccessFeedback), findsNothing);
      expect(
        find.text("Your data has not been disclosed to Gemeente"),
        findsOneWidget,
      );
    });
  });

  // The numbers are those of the boards J1 and J2 (390 by 844 px).
  group("CalmSuccessFeedback layout", () {
    final white = theme.light;

    testWidgets("is a white page with a borderless bar of 56 px", (
      tester,
    ) async {
      await pumpScreen(tester, issuance(), flag: _Flag.on, language: "nl");
      final shot = await screenshot(tester);

      expect(
        tester.getRect(find.byType(AppBar)),
        const Rect.fromLTWH(0, 0, 390, 56),
      );
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        white,
      );
      for (final y in [0, 28, 54, 55, 56, 57, 300]) {
        expect(shot.at(10, y), white, reason: "pixel (10, $y)");
      }
    });

    testWidgets("flag off keeps the grey-white page and the bar border", (
      tester,
    ) async {
      await pumpScreen(tester, issuance(), flag: _Flag.off);
      final shot = await screenshot(tester);

      expect(shot.at(10, 300), theme.backgroundSecondary);
      expect(shot.at(10, 55), theme.tertiary);
    });

    testWidgets("centres the bar title in 18 px 600 black", (tester) async {
      await pumpScreen(tester, issuance(), flag: _Flag.on, language: "nl");

      final title = styleOf(tester, "Toegevoegd");

      expect(tester.getCenter(find.text("Toegevoegd")), const Offset(195, 28));
      expect(tester.getSize(find.text("Toegevoegd")).width, closeTo(104, 0.1));
      expect(title.fontSize, 18);
      expect(title.fontWeight, FontWeight.w600);
      expect(title.color, theme.dark);
    });

    testWidgets(
      "puts a 22 px black cross in a 48 px button 4 px from the edge",
      (tester) async {
        await pumpScreen(tester, issuance(), flag: _Flag.on);

        final icon = tester.widget<Icon>(find.byIcon(Icons.close));

        expect(
          tester.getRect(find.byType(IrmaIconButton)),
          const Rect.fromLTWH(338, 4, 48, 48),
        );
        expect(
          tester.getCenter(find.byIcon(Icons.close)),
          const Offset(362, 28),
        );
        expect(icon.size, 22);
        expect(icon.color, theme.dark);
      },
    );

    testWidgets("places the graphic at 230 by 239 px, 56 px from the bar", (
      tester,
    ) async {
      await pumpScreen(tester, issuance(), flag: _Flag.on);

      expect(
        tester.getRect(find.byType(SuccessGraphic)),
        const Rect.fromLTWH(80, 112, 230, 239),
      );
      expect(
        tester.getRect(
          find.descendant(
            of: find.byType(SuccessGraphic),
            matching: find.byType(SvgPicture),
          ),
        ),
        const Rect.fromLTWH(80, 112, 230, 239),
      );
    });

    testWidgets("sets the heading 24 px below the graphic in 20/28 bold", (
      tester,
    ) async {
      await pumpScreen(tester, issuance(), flag: _Flag.on, language: "nl");

      final heading = styleOf(tester, "De gegevens staan in je Yivi-app");
      final rect = tester.getRect(
        find.text("De gegevens staan in je Yivi-app"),
      );

      expect(rect.top, 375);
      expect(rect.center.dx, 195);
      // 318 px of text fits the 326 px column on one line, if the letters are
      // not spaced out.
      expect(rect.height, 28);
      expect(rect.width, closeTo(318.1, 0.1));
      expect(heading.fontSize, 20);
      expect(heading.height! * heading.fontSize!, 28);
      expect(heading.fontWeight, FontWeight.w700);
      expect(heading.color, theme.dark);
    });

    testWidgets("sets the text 24 px below the heading in 16/24 regular", (
      tester,
    ) async {
      await pumpScreen(tester, issuance(), flag: _Flag.on, language: "nl");

      final style = styleOf(tester, "Je vindt ze terug onder Gegevens.");
      final heading = tester.getRect(
        find.text("De gegevens staan in je Yivi-app"),
      );
      final text = tester.getRect(
        find.text("Je vindt ze terug onder Gegevens."),
      );

      expect(text.top, heading.bottom + 24);
      expect(text.height, 24);
      expect(text.width, closeTo(249.3, 0.1));
      expect(text.center.dx, 195);
      expect(style.fontSize, 16);
      expect(style.height! * style.fontSize!, 24);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.color, theme.dark);
    });

    testWidgets("keeps 24 px between a heading of two lines and the text", (
      tester,
    ) async {
      await pumpScreen(
        tester,
        disclosure(
          DisclosureFeedbackType.success,
          otherParty: "Gemeente Voorbeeld",
        ),
        flag: _Flag.on,
        language: "nl",
      );

      final heading = tester.getRect(
        find.text("Je gegevens zijn gedeeld met Gemeente Voorbeeld"),
      );
      final text = tester.getRect(find.text("Je kunt terug naar de website."));

      expect(heading.top, 375);
      expect(heading.height, 56);
      expect(text.top, 455);
    });

    testWidgets(
      "puts a 358 by 48 px button 16 px from the sides, 32 px from the bottom",
      (tester) async {
        await pumpScreen(tester, issuance(), flag: _Flag.on, language: "nl");

        final button = find.byKey(const Key("ok_button"));
        final style = styleOf(tester, "OK");

        expect(tester.getRect(button), const Rect.fromLTWH(16, 764, 358, 48));
        expect(style.fontSize, 16);
        expect(style.fontWeight, FontWeight.w700);
        expect(style.color, theme.light);
      },
    );

    testWidgets("keeps the button above a system inset taller than 32 px", (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.resetPadding);
      await pumpScreen(tester, issuance(), flag: _Flag.on);

      expect(
        tester.getRect(find.byKey(const Key("ok_button"))).bottom,
        844 - 48,
      );
    });

    testWidgets("shadows the footer upwards with 0 -1px 6px #E0E0E0", (
      tester,
    ) async {
      // Widget tests draw shadows without blur unless asked, and the binding
      // checks that the flag is back when the test ends.
      debugDisableShadows = false;
      await pumpScreen(tester, issuance(), flag: _Flag.on);
      final shot = await screenshot(tester);
      debugDisableShadows = true;

      final above = [for (var y = 736; y < 748; y++) shot.at(195, y).r];

      expect(above.first, white.r);
      expect(above.last, lessThan(0.95));
      expect(above.last, greaterThan(Colors.grey.shade300.r));
      expect(shot.at(195, 748), white);
    });

    testWidgets("scrolls on a small screen without overflowing", (
      tester,
    ) async {
      await pumpScreen(
        tester,
        disclosure(
          DisclosureFeedbackType.success,
          otherParty: "Gemeente Voorbeeld",
        ),
        flag: _Flag.on,
        language: "nl",
        size: const Size(320, 400),
      );

      await tester.scrollUntilVisible(
        find.text("Je kunt terug naar de website."),
        100,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key("ok_button")), findsOneWidget);
    });

    testWidgets("dismisses from the button and the cross", (tester) async {
      var dismissed = 0;
      await pumpScreen(
        tester,
        issuance(onDismiss: () => dismissed++),
        flag: _Flag.on,
      );

      await tester.tap(find.byKey(const Key("ok_button")));
      await tester.tap(find.byIcon(Icons.close));

      expect(dismissed, 2);
    });
  });
}
