import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/app.dart";
import "package:yivi_core/src/theme/theme.dart";

import "../helpers/test_translation_loader.dart";
import "pump_translated.dart";

/// The app's shell around [child], as `App` builds it, minus the router
/// and the app-level wrappers (lock gate, review gate, card transitions).
Widget testApp(
  Widget child, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale("en", "US"),
  List<Override> overrides = const [],
  List<NavigatorObserver> navigatorObservers = const [],
}) => ProviderScope(
  overrides: overrides,
  child: YiviTheme(
    builder: (context) => MaterialApp(
      theme: YiviTheme.variantsOf(context).data.themeData,
      darkTheme: YiviTheme.variantsOf(context).darkData.themeData,
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: TestTranslationLoader(
            basePath: "assets/locales",
            forcedLocale: locale,
          ),
        ),
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppState.defaultSupportedLocales(),
      navigatorObservers: navigatorObservers,
      home: child,
    ),
  ),
);

/// Sets the test view to [size] at pixel ratio 1, resets it after the test,
/// and pumps [testApp] until the locale files have loaded.
Future<void> pumpTestApp(
  WidgetTester tester,
  Widget child, {
  Size? size,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale("en", "US"),
  List<Override> overrides = const [],
  List<NavigatorObserver> navigatorObservers = const [],
}) async {
  if (size != null) {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
  }
  await pumpTranslated(
    tester,
    testApp(
      child,
      brightness: brightness,
      locale: locale,
      overrides: overrides,
      navigatorObservers: navigatorObservers,
    ),
  );
}
