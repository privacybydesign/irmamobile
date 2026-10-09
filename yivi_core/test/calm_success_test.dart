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

final _cheeringAsset = RegExp(r"success/success_[1-5]\.svg$");
final _calmAsset = RegExp(r"success/calm_[12]\.svg$");

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // StreamingSharedPreferences.instance is a process-wide singleton, so
  // clearAll() wipes the backing store between tests.
  Future<IrmaPreferences> prefs({required bool calmSuccess}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await prefs.clearAll();
    await prefs.setFeatureFlag(FeatureFlag.calmSuccess, calmSuccess);
    return prefs;
  }

  Widget host(IrmaPreferences prefs, Widget child, {String language = "en"}) {
    return ProviderScope(
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
          home: child,
        ),
      ),
    );
  }

  // The translation loader reads the locale files with real IO, which only
  // completes outside the test's fake clock.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
  }

  String shownAsset(WidgetTester tester) {
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    return (svg.bytesLoader as SvgAssetLoader).assetName;
  }

  group("SuccessGraphic", () {
    testWidgets("shows a cheering illustration with the flag off", (
      tester,
    ) async {
      await tester.pumpWidget(
        host(await prefs(calmSuccess: false), const SuccessGraphic()),
      );
      await settle(tester);

      expect(shownAsset(tester), matches(_cheeringAsset));
    });

    testWidgets("shows a calm illustration with the flag on", (tester) async {
      await tester.pumpWidget(
        host(await prefs(calmSuccess: true), const SuccessGraphic()),
      );
      await settle(tester);

      expect(shownAsset(tester), matches(_calmAsset));
    });
  });

  group("IssuanceSuccessScreen", () {
    testWidgets("keeps the current copy with the flag off", (tester) async {
      await tester.pumpWidget(
        host(
          await prefs(calmSuccess: false),
          IssuanceSuccessScreen(onDismiss: (_) {}),
        ),
      );
      await settle(tester);

      expect(find.text("Success"), findsWidgets);
      expect(
        find.text("The data has been successfully added to Yivi"),
        findsOneWidget,
      );
      expect(find.text("Added"), findsNothing);
    });

    testWidgets("shows the neutral copy with the flag on", (tester) async {
      await tester.pumpWidget(
        host(
          await prefs(calmSuccess: true),
          IssuanceSuccessScreen(onDismiss: (_) {}),
          language: "nl",
        ),
      );
      await settle(tester);

      expect(find.text("Toegevoegd"), findsOneWidget);
      expect(
        find.text(
          "De gegevens staan in je Yivi-app. Je vindt ze terug onder Gegevens.",
        ),
        findsOneWidget,
      );
    });
  });

  group("DisclosureFeedbackScreen", () {
    Widget screen(
      IrmaPreferences prefs,
      DisclosureFeedbackType type, {
      bool signature = false,
    }) => host(
      prefs,
      DisclosureFeedbackScreen(
        feedbackType: type,
        otherParty: "Gemeente",
        isSignatureSession: signature,
        onDismiss: (_) {},
      ),
    );

    testWidgets("keeps the current copy with the flag off", (tester) async {
      await tester.pumpWidget(
        screen(await prefs(calmSuccess: false), DisclosureFeedbackType.success),
      );
      await settle(tester);

      expect(find.text("Your data is disclosed to Gemeente"), findsOneWidget);
      expect(find.text("Shared"), findsNothing);
    });

    testWidgets("shows the neutral copy with the flag on", (tester) async {
      await tester.pumpWidget(
        screen(await prefs(calmSuccess: true), DisclosureFeedbackType.success),
      );
      await settle(tester);

      expect(find.text("Shared"), findsOneWidget);
      expect(
        find.text("Your data has been shared with Gemeente"),
        findsOneWidget,
      );
    });

    testWidgets("leaves signature sessions alone with the flag on", (
      tester,
    ) async {
      await tester.pumpWidget(
        screen(
          await prefs(calmSuccess: true),
          DisclosureFeedbackType.success,
          signature: true,
        ),
      );
      await settle(tester);

      expect(find.text("You signed the request of Gemeente"), findsOneWidget);
      expect(find.text("Shared"), findsNothing);
    });

    testWidgets("leaves a canceled disclosure alone with the flag on", (
      tester,
    ) async {
      await tester.pumpWidget(
        screen(await prefs(calmSuccess: true), DisclosureFeedbackType.canceled),
      );
      await settle(tester);

      expect(
        find.text("Your data has not been disclosed to Gemeente"),
        findsOneWidget,
      );
    });
  });
}
