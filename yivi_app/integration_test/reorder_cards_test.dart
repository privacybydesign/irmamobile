import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";

import "helpers/helpers.dart";
import "helpers/issuance_helpers.dart";
import "irma_binding.dart";
import "util.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  // The data tab lists one card per credential instance and stores their
  // order as instance hashes (preference.card_order). Every credential type
  // below is issued once, so the order is compared as credential type ids.
  // Every view can be reordered (long press, then drag); this uses the List.
  group("card-reordering", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("reorder-cards-behavior", (tester) async {
      await pumpFilledAppOnDataPage(tester, irmaBinding);
      await showWalletView(tester, WalletView.list);
      // Let the debounced order save land.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      final beforeOrderOnDisk = await getCardOrderOnDisk(tester, irmaBinding);
      final beforeOrderOnScreen = walletCardCredentialIds(tester);

      expect(beforeOrderOnScreen, equals(beforeOrderOnDisk));
      expect(
        beforeOrderOnDisk,
        equals([
          "irma-demo.ivido.login",
          "irma-demo.gemeente.address",
          "irma-demo.gemeente.personalData",
          "irma-demo.sidn-pbdf.email",
          "irma-demo.IRMATube.member",
        ]),
      );

      final firstCard = findAllWalletCards().first;
      final secondCard = findAllWalletCards().at(1);
      final firstCenter = tester.getCenter(firstCard);
      final dragDistance = tester.getCenter(secondCard).dy - firstCenter.dy;

      final gesture = await tester.startGesture(firstCenter, kind: .touch);

      // long press: the card lifts
      await tester.pump(const Duration(milliseconds: 600));
      // Drag down just past the second card's place, in small increments so
      // the drag is followed across intermediate frames.
      const dragSteps = 10;
      for (var i = 0; i < dragSteps; i++) {
        await gesture.moveBy(Offset(0, (dragDistance + 10) / dragSteps));
        await tester.pump(const Duration(milliseconds: 16));
      }

      // release
      await gesture.up();
      await tester.pumpAndSettle();

      // let the reorder ghost/lift animation fully clear from the overlay
      // and give shared preferences time to update (the save is debounced)
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      final orderAfterDragOnDisk = await getCardOrderOnDisk(
        tester,
        irmaBinding,
      );
      final orderAfterDragOnScreen = walletCardCredentialIds(tester);

      expect(orderAfterDragOnScreen, equals(orderAfterDragOnDisk));
      expect(
        orderAfterDragOnDisk,
        equals([
          "irma-demo.gemeente.address",
          "irma-demo.ivido.login",
          "irma-demo.gemeente.personalData",
          "irma-demo.sidn-pbdf.email",
          "irma-demo.IRMATube.member",
        ]),
      );

      // now delete a card and make sure the order is updated correctly
      await deletePersonalDataCard(tester);

      final orderAfterDeleteOnDisk = await getCardOrderOnDisk(
        tester,
        irmaBinding,
      );
      final orderAfterDeleteOnScreen = walletCardCredentialIds(tester);

      expect(orderAfterDeleteOnScreen, equals(orderAfterDeleteOnDisk));
      expect(
        orderAfterDeleteOnDisk,
        equals([
          "irma-demo.gemeente.address",
          "irma-demo.ivido.login",
          "irma-demo.sidn-pbdf.email",
          "irma-demo.IRMATube.member",
        ]),
      );

      // after issuing again it should now be the top one
      await issueMunicipalityPersonalData(tester, irmaBinding);
      await tester.tapAndSettle(find.byKey(const Key("ok_button")));
      await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
      // Let the debounced order save land.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      final finalOrderOnDisk = await getCardOrderOnDisk(tester, irmaBinding);
      final finalOrderOnScreen = walletCardCredentialIds(tester);

      expect(finalOrderOnScreen, equals(finalOrderOnDisk));
      expect(
        finalOrderOnDisk,
        equals([
          "irma-demo.gemeente.personalData",
          "irma-demo.gemeente.address",
          "irma-demo.ivido.login",
          "irma-demo.sidn-pbdf.email",
          "irma-demo.IRMATube.member",
        ]),
      );
    });
  });
}

Future<void> deletePersonalDataCard(WidgetTester tester) async {
  await navigateToCredentialDetailsPage(
    tester,
    "irma-demo.gemeente.personalData",
  );
  await deleteCredentialFromDetail(tester);

  // wait for snackbar to disappear, and for the debounced order save
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

/// The stored card order (instance hashes), as credential type ids. Every
/// stored hash must belong to a card in the wallet.
Future<List<String>> getCardOrderOnDisk(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  final hashes = irmaBinding.repository.preferences.getCardOrder();
  final idByHash = {for (final c in walletCards(tester)) c.hash: c.credentialId};
  for (final hash in hashes) {
    expect(idByHash, contains(hash), reason: "stored hash not in wallet");
  }
  return hashes.map((h) => idByHash[h]!).toList();
}

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
