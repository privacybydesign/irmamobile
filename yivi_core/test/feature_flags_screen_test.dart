import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/providers/feature_flag_provider.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/screens/debug/debug_screen.dart";
import "package:yivi_core/src/screens/debug/feature_flags_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

class _SilentBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

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

  Future<void> pumpApp(WidgetTester tester, Widget home) async {
    final widget = ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
      child: IrmaRepositoryProvider(
        repository: IrmaRepository(client: _SilentBridge(), preferences: prefs),
        child: IrmaTheme(
          builder: (_) => MaterialApp.router(
            localizationsDelegates: [
              FlutterI18nDelegate(
                translationLoader: FileTranslationLoader(
                  basePath: "assets/locales",
                  forcedLocale: const Locale("en", "US"),
                ),
              ),
              ...GlobalMaterialLocalizations.delegates,
            ],
            // Mirrors the nesting in routing.dart: the real router builds the
            // whole home screen, which needs far more setup than this test.
            routerConfig: GoRouter(
              initialLocation: "/home/debug",
              routes: [
                GoRoute(
                  path: "/home",
                  builder: (context, state) => const SizedBox(),
                  routes: [
                    GoRoute(
                      path: "debug",
                      builder: (context, state) => home,
                      routes: [
                        GoRoute(
                          path: "feature_flags",
                          builder: (context, state) =>
                              const FeatureFlagsScreen(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // FileTranslationLoader reads the locale JSON with real IO, which the test
    // framework's fake clock does not drive.
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
  }

  Finder switchFor(FeatureFlag flag) => find.widgetWithText(
    SwitchListTile,
    "${flag.id} · ${flag.name}",
    skipOffstage: false,
  );

  Future<bool?> stored(WidgetTester tester, FeatureFlag flag) =>
      tester.runAsync(() => prefs.getFeatureFlag(flag).first);

  bool isOn(WidgetTester tester, FeatureFlag flag) =>
      tester.widget<SwitchListTile>(switchFor(flag)).value;

  // Storage writes finish on the real event loop, not the test's fake clock.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  test("every flag is off by default and stored under its own key", () async {
    for (final flag in FeatureFlag.values) {
      expect(await prefs.getFeatureFlag(flag).first, isFalse);
    }

    final keys = FeatureFlag.values.map((flag) => flag.prefKey).toSet();
    expect(keys, hasLength(FeatureFlag.values.length));
    expect(
      FeatureFlag.onboardingV2.prefKey,
      "preference.feature_flag.onboardingV2",
    );
  });

  test("a stored flag is on in a new IrmaPreferences (app restart)", () async {
    await prefs.setFeatureFlag(FeatureFlag.calmSuccess, true);

    final restarted = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );

    expect(await restarted.getFeatureFlag(FeatureFlag.calmSuccess).first, true);
    expect(
      await restarted.getFeatureFlag(FeatureFlag.shareScreenV2).first,
      false,
    );
  });

  test("featureFlagProvider emits the new value when a flag changes", () async {
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final emitted = <bool>[];
    container.listen(
      featureFlagProvider(FeatureFlag.emailLinking),
      (_, next) => next.whenData(emitted.add),
      fireImmediately: true,
    );

    await container.read(featureFlagProvider(FeatureFlag.emailLinking).future);
    await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, [false, true]);
  });

  testWidgets("switching a flag persists it and updates the provider", (
    tester,
  ) async {
    await pumpApp(tester, const FeatureFlagsScreen());

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FeatureFlagsScreen)),
    );
    expect(isOn(tester, FeatureFlag.dataTabV2), isFalse);

    await tester.tap(switchFor(FeatureFlag.dataTabV2));
    await settle(tester);

    expect(isOn(tester, FeatureFlag.dataTabV2), isTrue);
    expect(await stored(tester, FeatureFlag.dataTabV2), isTrue);
    expect(
      container.read(featureFlagProvider(FeatureFlag.dataTabV2)).value,
      true,
    );
    expect(isOn(tester, FeatureFlag.formFieldsV2), isFalse);
  });

  testWidgets("All on and All off switch every flag", (tester) async {
    // The list builds lazily; make the window tall enough to hold every tile.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 4000);
    addTearDown(tester.view.reset);

    await pumpApp(tester, const FeatureFlagsScreen());

    await tester.tap(find.text("All on"));
    await settle(tester);

    for (final flag in FeatureFlag.values) {
      expect(isOn(tester, flag), isTrue, reason: flag.name);
      expect(await stored(tester, flag), isTrue);
    }

    await tester.tap(find.text("All off"));
    await settle(tester);

    for (final flag in FeatureFlag.values) {
      expect(isOn(tester, flag), isFalse, reason: flag.name);
      expect(await stored(tester, flag), isFalse);
    }
  });

  testWidgets("the debug screen opens the feature flags screen", (
    tester,
  ) async {
    await pumpApp(tester, const DebugScreen());

    await tester.tap(find.text("Feature flags"));
    await tester.pumpAndSettle();

    expect(find.byType(FeatureFlagsScreen), findsOneWidget);
  });
}
