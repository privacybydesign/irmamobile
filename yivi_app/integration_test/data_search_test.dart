import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";

import "helpers/helpers.dart";
import "helpers/issuance_helpers.dart";
import "irma_binding.dart";
import "util.dart";

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // this line makes sure the text entering works on Firebase iOS on-device integration tests
  binding.testTextInput.register();

  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  // The data tab shows one card per credential instance; each test below
  // issues every credential type once, so cards and types coincide. The
  // search field is always visible and filters as you type (there is no
  // separate search mode any more).
  group("search-credentials", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("empty-app-shows-image", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

      final image = find.byKey(const Key("to_add_data_button_pointing_image"));
      expect(image, findsOneWidget);
    });

    testWidgets("empty-app-search-no-crash", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

      expect(countCredentialCards(tester), equals(0));

      await searchWallet(tester, "hello");
      expect(countCredentialCards(tester), equals(0));
      // The empty wallet keeps showing its explanation while searching.
      expect(
        find.byKey(const Key("to_add_data_button_pointing_image")),
        findsOneWidget,
      );

      await searchWallet(tester, "");
      expect(countCredentialCards(tester), equals(0));
    });

    testWidgets("no-query-all-cards", (tester) async {
      await pumpFilledAppOnDataPage(tester, irmaBinding);

      final numCredentials = countCredentialCards(tester);
      expect(numCredentials, equals(5));

      await pressFirstCredentialCard(tester);
      expect(findCredentialDetail(), findsOneWidget);
    });

    testWidgets("query-for-single", (tester) async {
      await pumpFilledAppOnDataPage(tester, irmaBinding);
      await searchWallet(tester, "tube");

      final expectedNumResults = 1;
      expect(countCredentialCards(tester), equals(expectedNumResults));
      expect(
        walletCardCredentialIds(tester),
        equals(["irma-demo.IRMATube.member"]),
      );

      await pressFirstCredentialCard(tester);
      expect(findCredentialDetail(), findsOneWidget);

      await closeCredentialDetail(tester);

      // expect the search query to still be applied
      expect(countCredentialCards(tester), equals(expectedNumResults));
    });

    testWidgets("query-for-two", (tester) async {
      await pumpFilledAppOnDataPage(tester, irmaBinding);
      await searchWallet(tester, "adres");

      final numCreds = countCredentialCards(tester);
      expect(numCreds, equals(2));

      await pressFirstCredentialCard(tester);
      expect(findCredentialDetail(), findsOneWidget);
    });

    testWidgets("clearing-query-shows-all-cards", (tester) async {
      await pumpFilledAppOnDataPage(tester, irmaBinding);
      await searchWallet(tester, "tube");
      expect(countCredentialCards(tester), equals(1));

      await searchWallet(tester, "");
      expect(countCredentialCards(tester), equals(5));
    });
  });
}

/// Opens the detail view of the first card on the data tab. Uses the list
/// view, as the stack view overlaps the cards.
Future<void> pressFirstCredentialCard(WidgetTester tester) async {
  await showWalletView(tester, WalletView.list);
  await tester.tapAndSettle(findAllWalletCards().first);
  await tester.waitFor(findCredentialDetail());
}

/// The number of cards the data tab shows.
int countCredentialCards(WidgetTester tester) =>
    walletCardCredentialIds(tester).length;

Future<void> pumpFilledAppOnDataPage(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(
    tester,
    irmaBinding.repository,
    defaultLanguage: Locale("en"),
  );
  await fillApp(tester, irmaBinding);
  await tester.tapAndSettle(find.byKey(const Key("ok_button")));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
}

Future<void> fillApp(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await issueIrmaTubeMember(tester, irmaBinding);
  await issueDemoCredentials(tester, irmaBinding);
  await issueDemoIvidoLogin(tester, irmaBinding);
}
