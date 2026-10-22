import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/data/wallet/wallet_detail_scaffold.dart";
import "package:yivi_core/src/theme/theme.dart";

import "helpers/test_translation_loader.dart";

void main() {
  testWidgets("a hard pull down closes the detail page and only that page", (
    tester,
  ) async {
    // The page below, like home: a pop that reaches it sends the app to the
    // background.
    var popsBelow = 0;
    late BuildContext below;
    await tester.pumpWidget(
      IrmaTheme(
        builder: (context) => MaterialApp(
          theme: IrmaTheme.variantsOf(context).data.themeData,
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: TestTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: const Locale("en", "US"),
              ),
            ),
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: PopScope(
            canPop: false,
            onPopInvokedWithResult: (_, _) => popsBelow++,
            child: Builder(
              builder: (context) {
                below = context;
                return const Scaffold(body: Text("below"));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Navigator.of(below).push(
      MaterialPageRoute<void>(
        builder: (_) => WalletDetailScaffold(
          openKey: "detail",
          closeKey: const Key("detail_close"),
          builder: (context, physics, animation) => ListView(
            key: const Key("detail_list"),
            physics: physics,
            children: [
              for (var i = 0; i < 30; i++)
                SizedBox(height: 80, child: Text("row $i")),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("row 0"), findsOneWidget);

    await tester.fling(
      find.byKey(const Key("detail_list")),
      const Offset(0, 500),
      4000,
    );
    await tester.pumpAndSettle();

    expect(find.text("row 0"), findsNothing);
    expect(find.text("below"), findsOneWidget);
    expect(popsBelow, 0);
  });
}
