import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/translation_loader.dart";
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

/// Empty translations: the screen is plain English, but the shared app bar
/// still looks up its back button label.
class _NoopTranslationLoader extends TranslationLoader {
  @override
  Future<Map> load() async => <String, dynamic>{};
}

class _NoopBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // StreamingSharedPreferences.instance is a process-wide singleton, so
  // setMockInitialValues alone does not reset values between tests. clearAll()
  // wipes the backing store, giving each test a clean slate.
  Future<IrmaPreferences> freshPrefs() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await prefs.clearAll();
    return prefs;
  }

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester,
    IrmaPreferences prefs,
  ) async {
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: IrmaTheme(
          builder: (_) => MaterialApp(
            localizationsDelegates: [
              FlutterI18nDelegate(translationLoader: _NoopTranslationLoader()),
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: const FeatureFlagsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return container;
  }

  Finder flagTile(FeatureFlag flag) =>
      find.byKey(Key("feature_flag_${flag.name}"));

  Future<void> scrollToFlag(WidgetTester tester, FeatureFlag flag) =>
      tester.scrollUntilVisible(flagTile(flag), 200);

  bool tileValue(WidgetTester tester, FeatureFlag flag) =>
      tester.widget<SwitchListTile>(flagTile(flag)).value;

  // Streams need real async; awaiting them directly hangs under the fake clock.
  Future<bool> stored(
    WidgetTester tester,
    IrmaPreferences prefs,
    FeatureFlag flag,
  ) async => (await tester.runAsync(() => prefs.getFeatureFlag(flag).first))!;

  test("every flag defaults to off", () async {
    final prefs = await freshPrefs();

    for (final flag in FeatureFlag.values) {
      expect(
        await prefs.getFeatureFlag(flag).first,
        isFalse,
        reason: flag.name,
      );
    }
  });

  test("flags are stored under their own key", () async {
    final prefs = await freshPrefs();

    await prefs.setFeatureFlag(FeatureFlag.onboardingV2, true);

    expect(await prefs.getFeatureFlag(FeatureFlag.onboardingV2).first, isTrue);
    expect(await prefs.getFeatureFlag(FeatureFlag.emailLinking).first, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        "preference.feature_flag.onboardingV2",
      ),
      isTrue,
    );
  });

  testWidgets("switching a flag persists it and the provider emits it", (
    tester,
  ) async {
    final prefs = await freshPrefs();
    final container = await pumpScreen(tester, prefs);

    final emitted = <bool>[];
    container.listen<AsyncValue<bool>>(
      featureFlagProvider(FeatureFlag.singleTapChoice),
      (_, next) => emitted.add(next.value ?? false),
      fireImmediately: true,
    );
    await tester.pumpAndSettle();

    await scrollToFlag(tester, FeatureFlag.singleTapChoice);
    expect(tileValue(tester, FeatureFlag.singleTapChoice), isFalse);

    await tester.tap(flagTile(FeatureFlag.singleTapChoice));
    await tester.pumpAndSettle();

    expect(tileValue(tester, FeatureFlag.singleTapChoice), isTrue);
    expect(await stored(tester, prefs, FeatureFlag.singleTapChoice), isTrue);
    expect(emitted.last, isTrue);
    expect(await stored(tester, prefs, FeatureFlag.calmSuccess), isFalse);
  });

  testWidgets("a stored flag is shown on after a restart", (tester) async {
    final prefs = await freshPrefs();
    await prefs.setFeatureFlag(FeatureFlag.shareScreenV2, true);

    // A new IrmaPreferences over the same store stands in for a restart.
    final restarted = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await pumpScreen(tester, restarted);

    expect(tileValue(tester, FeatureFlag.onboardingV2), isFalse);
    await scrollToFlag(tester, FeatureFlag.shareScreenV2);
    expect(tileValue(tester, FeatureFlag.shareScreenV2), isTrue);
  });

  testWidgets("All on and All off switch every flag", (tester) async {
    final prefs = await freshPrefs();
    await pumpScreen(tester, prefs);

    await tester.tap(find.byKey(const Key("feature_flags_all_on")));
    await tester.pumpAndSettle();

    for (final flag in FeatureFlag.values) {
      expect(await stored(tester, prefs, flag), isTrue, reason: flag.name);
    }

    await tester.tap(find.byKey(const Key("feature_flags_all_off")));
    await tester.pumpAndSettle();

    for (final flag in FeatureFlag.values) {
      expect(await stored(tester, prefs, flag), isFalse, reason: flag.name);
    }
  });

  testWidgets("the debug screen opens the feature flags screen", (
    tester,
  ) async {
    final prefs = await freshPrefs();
    final repo = IrmaRepository(client: _NoopBridge(), preferences: prefs);
    // Mirrors the nesting in routing.dart, which pushFeatureFlagsScreen targets.
    final router = GoRouter(
      initialLocation: "/home/debug",
      routes: [
        GoRoute(
          path: "/home",
          builder: (context, state) => const SizedBox(),
          routes: [
            GoRoute(
              path: "debug",
              builder: (context, state) => const DebugScreen(),
              routes: [
                GoRoute(
                  path: "feature_flags",
                  builder: (context, state) => const FeatureFlagsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
        child: IrmaRepositoryProvider(
          repository: repo,
          child: IrmaTheme(
            builder: (_) => MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: [
                FlutterI18nDelegate(
                  translationLoader: _NoopTranslationLoader(),
                ),
                ...GlobalMaterialLocalizations.delegates,
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("debug_feature_flags")));
    await tester.pumpAndSettle();

    expect(find.byType(FeatureFlagsScreen), findsOneWidget);
  });
}
