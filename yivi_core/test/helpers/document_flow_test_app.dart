import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/test_detection.dart";

import "test_translation_loader.dart";

/// The size of the phone the document flow boards are drawn for.
const documentFlowPhone = Size(390, 844);

/// Whether the animations that loop on a ticker run.
enum Ticker { stopped, running }

/// The localization delegates of the app, with the locale files of [locale].
List<LocalizationsDelegate<dynamic>> documentFlowDelegates(Locale locale) => [
  FlutterI18nDelegate(
    translationLoader: TestTranslationLoader(
      basePath: "assets/locales",
      forcedLocale: locale,
    ),
  ),
  ...GlobalMaterialLocalizations.delegates,
];

/// Pumps [home] in the app's theme and a [ProviderScope] with [overrides], on
/// a phone of [surface] (the boards' phone by default).
///
/// With [Ticker.stopped], TestContext stops the animations that loop on a
/// ticker and the tree is settled. With [Ticker.running] they run, so the tree
/// is only pumped until the locale files are in.
Future<void> pumpDocumentFlow(
  WidgetTester tester,
  Widget home, {
  Locale locale = const Locale("en", "US"),
  List<Override> overrides = const [],
  Ticker ticker = Ticker.stopped,
  Size surface = documentFlowPhone,
}) async {
  tester.view
    ..physicalSize = surface
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  Widget app = IrmaTheme(
    builder: (_) => MaterialApp(
      localizationsDelegates: documentFlowDelegates(locale),
      home: home,
    ),
  );
  if (ticker == Ticker.stopped) app = TestContext(child: app);

  await tester.pumpWidget(ProviderScope(overrides: overrides, child: app));
  if (ticker == Ticker.stopped) {
    await tester.pumpAndSettle();
    return;
  }
  await pumpUntilLocalized(tester);
}

/// Pumps frames until the locale files are loaded. Until then Localizations
/// builds an empty box instead of its child, so the Directionality it wraps its
/// child in is missing.
Future<void> pumpUntilLocalized(WidgetTester tester) async {
  bool loaded() => tester.any(
    find.descendant(
      of: find.byType(Localizations).first,
      matching: find.byType(Directionality),
    ),
  );
  for (var i = 0; i < 50 && !loaded(); i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(loaded(), isTrue, reason: "the locale files did not load");
}
