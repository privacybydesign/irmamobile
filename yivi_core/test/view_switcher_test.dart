import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/theme/theme.dart";

import "helpers/test_translation_loader.dart";

Widget _wrap(WalletView view) => IrmaTheme(
  builder: (_) => MaterialApp(
    localizationsDelegates: [
      FlutterI18nDelegate(
        translationLoader: TestTranslationLoader(
          basePath: "assets/locales",
          forcedLocale: const Locale("en", "US"),
        ),
      ),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: Scaffold(
      body: Center(
        child: ViewSwitcher(view: view, onChanged: (_) {}),
      ),
    ),
  ),
);

void main() {
  // The marker overshoots as it slides, but never past the ends of the
  // switch, where it would be cut off.
  testWidgets("the marker stays inside the switch while it bounces", (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(WalletView.stack));
    await tester.pumpAndSettle();
    final outer = tester.getRect(find.byKey(const Key("wallet_view_stack")));
    final end = tester.getRect(find.byKey(const Key("wallet_view_grid")));
    final marker = find.byKey(const Key("wallet_view_marker"));

    for (final view in [WalletView.grid, WalletView.stack]) {
      await tester.pumpWidget(_wrap(view));
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final rect = tester.getRect(marker);
        expect(rect.left, greaterThanOrEqualTo(outer.left - 0.01));
        expect(rect.right, lessThanOrEqualTo(end.right + 0.01));
      }
    }
    expect(
      tester.getRect(marker),
      tester.getRect(find.byKey(const Key("wallet_view_stack"))),
    );
  });
}
