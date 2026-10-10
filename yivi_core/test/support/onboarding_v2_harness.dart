import "dart:async";

import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/theme/theme.dart";

import "pump_translated.dart";

/// A bridge that records what the app sends and lets a test answer it.
class RecordingBridge extends IrmaBridge {
  final List<Event> dispatched = [];

  /// Called for every dispatched event; a returned event is sent back.
  Event? Function(Event event)? respond;

  @override
  void dispatch(Event event) {
    dispatched.add(event);
    final reply = respond?.call(event);
    if (reply != null) scheduleMicrotask(() => addEvent(reply));
  }
}

/// Preferences over a clean store. StreamingSharedPreferences is a
/// process-wide singleton, so clearAll() is what isolates the tests.
Future<IrmaPreferences> freshPreferences() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await IrmaPreferences.fromInstance(
    mostRecentTermsUrlNl: "https://example.com/nl",
    mostRecentTermsUrlEn: "https://example.com/en",
  );
  await preferences.clearAll();
  return preferences;
}

Future<void> setOnboardingV2(IrmaPreferences preferences, {required bool on}) =>
    preferences.setFeatureFlag(FeatureFlag.onboardingV2, on);

/// Lets writes to the preference store finish; they run on the real event loop
/// rather than the test's fake clock.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump(const Duration(milliseconds: 100));
}

Widget _app({
  required IrmaRepository repo,
  required List<Override> overrides,
  required Locale locale,
  required Widget Function(List<LocalizationsDelegate<dynamic>>) builder,
}) => ProviderScope(
  overrides: [
    preferencesProvider.overrideWithValue(repo.preferences),
    ...overrides,
  ],
  child: IrmaRepositoryProvider(
    repository: repo,
    child: IrmaTheme(
      builder: (_) => builder([
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            basePath: "assets/locales",
            forcedLocale: locale,
          ),
        ),
        ...GlobalMaterialLocalizations.delegates,
      ]),
    ),
  ),
);

Future<void> pumpHome(
  WidgetTester tester, {
  required IrmaRepository repo,
  required Widget home,
  List<Override> overrides = const [],
  Locale locale = const Locale("en", "US"),
}) => pumpTranslated(
  tester,
  _app(
    repo: repo,
    overrides: overrides,
    locale: locale,
    builder: (delegates) => MaterialApp(
      localizationsDelegates: delegates,
      home: Scaffold(body: home),
    ),
  ),
);

/// Pumps [routes] and returns the router, so a test can read the location.
Future<GoRouter> pumpRoutes(
  WidgetTester tester, {
  required IrmaRepository repo,
  required List<RouteBase> routes,
  required String initialLocation,
  List<Override> overrides = const [],
  Locale locale = const Locale("en", "US"),
}) async {
  final router = GoRouter(initialLocation: initialLocation, routes: routes);
  await pumpTranslated(
    tester,
    _app(
      repo: repo,
      overrides: overrides,
      locale: locale,
      builder: (delegates) => MaterialApp.router(
        localizationsDelegates: delegates,
        routerConfig: router,
      ),
    ),
  );
  return router;
}

String currentLocation(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;
