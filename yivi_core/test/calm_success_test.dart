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
import "package:yivi_core/src/screens/session/widgets/disclosure_feedback_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/screens/session/widgets/success_graphic.dart";
import "package:yivi_core/src/theme/theme.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IrmaPreferences prefs;

  setUpAll(() => SharedPreferences.setMockInitialValues({}));

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
    required bool calm,
    String language = "en",
  }) async {
    await prefs.setFeatureFlag(FeatureFlag.calmSuccess, calm);

    final widget = ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
      child: IrmaTheme(
        builder: (_) => MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: FileTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: Locale(language),
              ),
            ),
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: screen,
        ),
      ),
    );

    // The locale JSON is read with real IO, which the test framework's fake
    // clock does not drive. The flag arrives through a stream, so the screen
    // is first built with it off and rebuilt by the second pump.
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump();
  }

  String graphicAsset(WidgetTester tester) {
    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    return (picture.bytesLoader as SvgAssetLoader).assetName;
  }

  Widget issuance() => IssuanceSuccessScreen(onDismiss: (_) {});

  Widget disclosure(
    DisclosureFeedbackType type, {
    bool isSignatureSession = false,
  }) => DisclosureFeedbackScreen(
    feedbackType: type,
    otherParty: "Gemeente",
    isSignatureSession: isSignatureSession,
    onDismiss: (_) {},
  );

  group("SuccessGraphic", () {
    final classic = RegExp(r"assets/success/success_[1-5]\.svg$");
    final calmAsset = RegExp(r"assets/success/calm_[1-2]\.svg$");

    testWidgets("flag off shows one of the five cheering people", (
      tester,
    ) async {
      await pumpScreen(tester, const SuccessGraphic(), calm: false);

      expect(graphicAsset(tester), matches(classic));
    });

    testWidgets("flag on shows one of the two calm people", (tester) async {
      await pumpScreen(tester, const SuccessGraphic(), calm: true);

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
        calm: true,
      );

      final assets = tester
          .widgetList<SvgPicture>(find.byType(SvgPicture))
          .map((picture) => (picture.bytesLoader as SvgAssetLoader).assetName);

      expect(assets.toSet(), hasLength(2));
    });
  });

  group("IssuanceSuccessScreen", () {
    testWidgets("flag off keeps the current copy", (tester) async {
      await pumpScreen(tester, issuance(), calm: false);

      expect(find.text("Success"), findsWidgets);
      expect(
        find.text("The data has been successfully added to Yivi"),
        findsOneWidget,
      );
      expect(find.text("Added"), findsNothing);
    });

    testWidgets("flag on shows the calm copy in Dutch", (tester) async {
      await pumpScreen(tester, issuance(), calm: true, language: "nl");

      expect(find.text("Toegevoegd"), findsOneWidget);
      expect(
        find.text(
          "De gegevens staan in je Yivi-app. Je vindt ze terug onder Gegevens.",
        ),
        findsOneWidget,
      );
      expect(find.textContaining("succesvol"), findsNothing);
    });

    testWidgets("flag on shows the calm copy in English", (tester) async {
      await pumpScreen(tester, issuance(), calm: true);

      expect(find.text("Added"), findsOneWidget);
      expect(
        find.text("The data is in your Yivi app. You can find it under Data."),
        findsOneWidget,
      );
    });

    testWidgets("flag off in Dutch has the spelling fixed", (tester) async {
      await pumpScreen(tester, issuance(), calm: false, language: "nl");

      expect(
        find.text("De gegevens zijn succesvol aan Yivi toegevoegd."),
        findsOneWidget,
      );
    });
  });

  group("DisclosureFeedbackScreen", () {
    testWidgets("flag off keeps the current copy", (tester) async {
      await pumpScreen(
        tester,
        disclosure(DisclosureFeedbackType.success),
        calm: false,
      );

      expect(find.text("Your data is disclosed to Gemeente"), findsOneWidget);
      expect(find.text("Shared"), findsNothing);
    });

    testWidgets("flag on shows the calm copy in Dutch", (tester) async {
      await pumpScreen(
        tester,
        disclosure(DisclosureFeedbackType.success),
        calm: true,
        language: "nl",
      );

      expect(find.text("Gedeeld"), findsOneWidget);
      expect(
        find.text("Je gegevens zijn gedeeld met Gemeente"),
        findsOneWidget,
      );
    });

    testWidgets("flag on shows the calm copy in English", (tester) async {
      await pumpScreen(
        tester,
        disclosure(DisclosureFeedbackType.success),
        calm: true,
      );

      expect(find.text("Shared"), findsOneWidget);
      expect(
        find.text("Your data has been shared with Gemeente"),
        findsOneWidget,
      );
    });

    testWidgets("flag on keeps the copy of a signature session", (
      tester,
    ) async {
      await pumpScreen(
        tester,
        disclosure(DisclosureFeedbackType.success, isSignatureSession: true),
        calm: true,
      );

      expect(find.text("You signed the request of Gemeente"), findsOneWidget);
      expect(find.text("Shared"), findsNothing);
    });

    testWidgets("flag on keeps the copy of a cancelled session", (
      tester,
    ) async {
      await pumpScreen(
        tester,
        disclosure(DisclosureFeedbackType.canceled),
        calm: true,
      );

      expect(
        find.text("Your data has not been disclosed to Gemeente"),
        findsOneWidget,
      );
    });
  });
}
