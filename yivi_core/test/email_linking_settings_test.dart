import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/screens/settings/settings_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

class _SilentBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IrmaPreferences prefs;

  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  setUp(() async {
    prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await prefs.clearAll();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    final widget = ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
      child: IrmaRepositoryProvider(
        repository: IrmaRepository(client: _SilentBridge(), preferences: prefs),
        child: IrmaTheme(
          builder: (_) => MaterialApp(
            localizationsDelegates: [
              FlutterI18nDelegate(
                translationLoader: FileTranslationLoader(
                  basePath: "assets/locales",
                  forcedLocale: const Locale("en", "US"),
                ),
              ),
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: SettingsScreen(),
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets("has no e-mail entry with the flag off", (tester) async {
    await pumpSettings(tester);

    expect(find.byKey(const Key("link_email_link")), findsNothing);
    expect(find.text("Link email address"), findsNothing);
  });

  testWidgets("offers to link an e-mail address with the flag on", (
    tester,
  ) async {
    await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);
    await pumpSettings(tester);

    expect(find.byKey(const Key("link_email_link")), findsOneWidget);
    expect(find.text("Link email address"), findsOneWidget);
  });

  testWidgets("drops the entry once an address is linked", (tester) async {
    await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);
    await prefs.markEmailLinked();
    await pumpSettings(tester);

    expect(find.byKey(const Key("link_email_link")), findsNothing);
  });
}
