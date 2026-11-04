import "package:cupertino_ui/cupertino_ui.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/providers/schemaless_credentials_provider.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/irma_icon_button.dart";

import "helpers/test_translation_loader.dart";

// Regression test for #726: the search and add data buttons in the top bar
// of the data tab had no label, so a screen reader announced only "button".

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDataTab(WidgetTester tester, Locale locale) async {
    final widget = ProviderScope(
      overrides: [
        schemalessCredentialsProvider.overrideWith(
          (ref) => Stream.value((credentials: [], problematic: [])),
        ),
      ],
      child: IrmaTheme(
        builder: (_) => MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: TestTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: locale,
              ),
            ),
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: DataTab(),
        ),
      ),
    );

    // FileTranslationLoader reads the locale JSON with real IO, which the test
    // framework's fake clock does not drive: without runAsync plus a real
    // delay, Localizations never rebuilds and the tree stays empty. Dutch
    // loads two files (nl.json plus the en.json fallback).
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  final searchButton = find.byKey(const Key("search_button"));
  final addButton = find.widgetWithIcon(
    IrmaIconButton,
    CupertinoIcons.add_circled_solid,
  );

  testWidgets("search button announces its label and button role", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpDataTab(tester, const Locale("en", "US"));

    expect(
      tester.getSemantics(searchButton),
      matchesSemantics(
        label: "Search your data",
        isButton: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );

    handle.dispose();
  });

  testWidgets("add data button announces its label and button role", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpDataTab(tester, const Locale("en", "US"));

    expect(
      tester.getSemantics(addButton),
      matchesSemantics(
        label: "Obtain data",
        isButton: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );

    handle.dispose();
  });

  testWidgets("button labels are localized", (tester) async {
    final handle = tester.ensureSemantics();
    await pumpDataTab(tester, const Locale("nl", "NL"));

    expect(tester.getSemantics(searchButton).label, "Zoek in je gegevens");
    expect(tester.getSemantics(addButton).label, "Haal gegevens op");

    handle.dispose();
  });
}
