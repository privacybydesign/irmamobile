import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/bank_account.dart";
import "package:yivi_core/src/providers/bank_accounts_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_provider.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/theme/theme.dart";

import "helpers/test_translation_loader.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDataTab(
    WidgetTester tester,
    List<BankConnection> connections,
  ) async {
    final widget = ProviderScope(
      overrides: [
        schemalessCredentialsProvider.overrideWith(
          (ref) => Stream.value((credentials: [], problematic: [])),
        ),
        bankConnectionsProvider.overrideWith((ref) async => connections),
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
          home: DataTab(),
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
  }

  final accountsSection = find.byKey(const Key("data_tab_section_accounts"));
  final credentialsSection = find.byKey(
    const Key("data_tab_section_credentials"),
  );

  testWidgets("the data tab opens on the credentials", (tester) async {
    await pumpDataTab(tester, const []);

    expect(find.text("Gegevens"), findsWidgets);
    expect(find.text("Rekeningen"), findsOneWidget);
    expect(find.byKey(const Key("search_button")), findsOneWidget);
    expect(find.byKey(const Key("bank_accounts_connect")), findsNothing);
  });

  testWidgets("the accounts section invites to add an account when empty", (
    tester,
  ) async {
    await pumpDataTab(tester, const []);
    await tester.tap(accountsSection);
    await tester.pumpAndSettle();

    expect(find.text("Je bankrekeningen"), findsOneWidget);
    expect(find.byKey(const Key("bank_accounts_connect")), findsOneWidget);
    expect(find.byKey(const Key("add_bank_account_button")), findsOneWidget);
    // searching is for credentials only
    expect(find.byKey(const Key("search_button")), findsNothing);

    await tester.tap(credentialsSection);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key("search_button")), findsOneWidget);
  });

  final connections = [
    BankConnection(
      consentId: "consent-1",
      status: .ready,
      bank: "ENSANDBOX",
      bankName: "Sandbox Bank",
      updatedAt: DateTime(2026, 11, 18, 9, 41),
      accounts: const [
        BankAccount(
          id: "acc-1",
          iban: "NL11ENAB1234567890",
          holder: "John Doe",
          currency: "EUR",
          balance: BankBalance(amount: 1843.27, currency: "EUR"),
        ),
        BankAccount(
          id: "acc-2",
          iban: "NL99ENAB0987654321",
          holder: "Jane Doe",
          currency: "EUR",
          balance: BankBalance(amount: 5200, currency: "EUR"),
        ),
      ],
    ),
    const BankConnection(
      consentId: "consent-2",
      status: .pending,
      bank: "INGBNL2A",
      bankName: "ING",
    ),
    const BankConnection.gone("consent-3"),
  ];

  Future<void> openAccounts(WidgetTester tester) async {
    await pumpDataTab(tester, connections);
    await tester.tap(accountsSection);
    // the pending connection shows a spinner, which never settles
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets("every account has its own card", (tester) async {
    await openAccounts(tester);

    expect(find.byKey(const Key("bank_account_acc-1")), findsOneWidget);
    expect(find.byKey(const Key("bank_account_acc-2")), findsOneWidget);
    expect(find.text("John Doe"), findsOneWidget);
    expect(find.text("NL11 ENAB 1234 5678 90"), findsOneWidget);
    expect(find.text("Sandbox Bank"), findsNWidgets(2));
    expect(find.textContaining("1.843,27"), findsOneWidget);
    expect(find.textContaining("Bijgewerkt 18 nov"), findsNWidgets(2));
    // the total of both accounts
    expect(find.text("Totaal saldo van 2 rekeningen"), findsOneWidget);
    expect(find.textContaining("7.043,27"), findsOneWidget);
  });

  testWidgets("connections without accounts explain themselves", (
    tester,
  ) async {
    await openAccounts(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key("bank_connection_consent-3")),
      200,
    );

    expect(find.text("ING"), findsOneWidget);
    expect(find.text("Je rekeningen worden opgehaald…"), findsOneWidget);
    expect(find.textContaining("is verlopen"), findsOneWidget);
    // only a broken connection can be removed as a whole
    expect(
      find.byKey(const Key("bank_connection_remove_consent-3")),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key("bank_connection_remove_consent-2")),
      findsNothing,
    );
  });

  testWidgets("an account can be updated, copied and removed", (tester) async {
    await openAccounts(tester);
    await tester.tap(find.byKey(const Key("bank_account_options_acc-1")));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text("Bijwerken"), findsOneWidget);
    expect(find.text("Rekeningnummer kopiëren"), findsOneWidget);
    expect(find.text("Rekening verwijderen"), findsOneWidget);
    // honest about what removing one of two accounts at a bank does
    expect(
      find.text(
        "De rekening verdwijnt uit Yivi. Je andere rekeningen bij Sandbox Bank blijven staan.",
      ),
      findsOneWidget,
    );
  });
}
