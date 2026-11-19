import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/bank_account.dart";
import "package:yivi_core/src/providers/bank_accounts_provider.dart";
import "package:yivi_core/src/screens/accounts/add_bank_account_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

import "helpers/test_translation_loader.dart";

class _Connector extends BankConnector {
  _Connector(super.ref);

  final chosen = <String?>[];

  @override
  Future<bool> connect({String? bank}) async {
    chosen.add(bank);
    // the user closed the browser
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("the user chooses the bank in the app", (tester) async {
    late _Connector connector;
    final widget = ProviderScope(
      overrides: [
        banksProvider.overrideWith(
          (ref) async => const [
            Bank(key: "ENSANDBOX", name: "Sandbox Bank"),
            Bank(key: "INGBNL2A", name: "ING"),
          ],
        ),
        bankConnectorProvider.overrideWith(
          (ref) => connector = _Connector(ref),
        ),
      ],
      child: IrmaTheme(
        builder: (_) => MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: TestTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: const Locale("nl", "NL"),
              ),
            ),
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: const AddBankAccountScreen(),
        ),
      ),
    );
    // see top_bar_buttons_semantics_test.dart: the locale files are read with
    // real IO, which the fake clock does not drive
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    expect(find.text("Kies je bank"), findsOneWidget);
    expect(find.text("Sandbox Bank"), findsOneWidget);
    expect(find.text("ING"), findsOneWidget);

    await tester.tap(find.byKey(const Key("bank_INGBNL2A")));
    await tester.pumpAndSettle();
    expect(connector.chosen, ["INGBNL2A"]);
    // still here, so the user can choose again
    expect(find.text("Kies je bank"), findsOneWidget);
  });
}
