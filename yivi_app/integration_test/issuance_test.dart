import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

import "helpers/helpers.dart";
import "helpers/issuance_helpers.dart";
import "irma_binding.dart";
import "util.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("issuance", () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    Future<void> testIssueMunicipality(
      WidgetTester tester,
      Locale locale,
    ) async {
      await pumpAndUnlockApp(
        tester,
        irmaBinding.repository,
        defaultLanguage: locale,
      );

      await issueMunicipalityPersonalData(tester, irmaBinding, locale: locale);
      await tester.pumpAndSettle();

      final successScreenFinder = find.byType(IssuanceSuccessScreen);
      expect(successScreenFinder, findsOneWidget);

      // The received card, with its check badge
      final successGraphicFinder = find.byKey(const Key("received_check"));
      expect(
        find.descendant(
          of: successScreenFinder,
          matching: successGraphicFinder,
        ),
        findsOneWidget,
      );

      await tester.tapAndSettle(find.text("OK"));

      // Go to data tab
      await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

      // Expect one card for the credential and open its detail view
      expect(
        findWalletCards("irma-demo.gemeente.personalData"),
        findsOneWidget,
      );
      await navigateToCredentialDetailsPage(
        tester,
        "irma-demo.gemeente.personalData",
      );

      // Expect the card's details
      expect(
        find.descendant(
          of: findCredentialDetail(),
          matching: find.byType(YiviCredentialCardAttributeList),
        ),
        findsOneWidget,
      );
    }

    testWidgets(
      "issue-municipality-en",
      (tester) => testIssueMunicipality(tester, const Locale("en", "EN")),
    );

    testWidgets(
      "issue-municipality-nl",
      (tester) => testIssueMunicipality(tester, const Locale("nl", "NL")),
    );

    testWidgets("decline", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // Start an issuance session for email address and decline the offer.
      await issueCredentials(tester, irmaBinding, {
        "irma-demo.sidn-pbdf.email.email": "test@demo.com",
        "irma-demo.sidn-pbdf.email.domain": "demo.com",
      }, declineOffer: true);

      // Go to data tab.
      await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

      // Verify that the email address has not been added.
      final emailTileFinder = find.byKey(
        const Key("irma-demo.sidn-pbdf.email_tile"),
      );
      expect(emailTileFinder, findsNothing);

      // Verify that no activity has been added.
      await tester.tap(find.byKey(const Key("nav_button_activity")));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text("There are no logged activities yet"), findsOneWidget);
    });

    testWidgets("reissue", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await issueEmailAddress(tester, irmaBinding);

      // Press ok
      final okButtonFinder = find.text("OK");
      await tester.tapAndSettle(okButtonFinder);

      // Go to data tab.
      await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

      // Expect one email card, and open it.
      const emailCredId = "irma-demo.sidn-pbdf.email";
      expect(findWalletCards(emailCredId), findsOneWidget);
      await navigateToCredentialDetailsPage(tester, emailCredId);

      // Expect the card to have the correct content
      Future<void> evaluateIssuedEmailAddressCard() => evaluateCredentialCard(
        tester,
        findCredentialDetail(),
        credentialName: "Demo Email address",
        issuerName: "Demo Privacy by Design Foundation via SIDN",
        attributes: [
          ("Email address", "test@example.com"),
          ("Email domain name", "example.com"),
        ],
      );

      await evaluateIssuedEmailAddressCard();

      // Issue the same credential again.
      await issueEmailAddress(tester, irmaBinding);
      await tester.tapAndSettle(okButtonFinder);

      // The reissued card replaces the old one: still one email card.
      if (tester.any(findCredentialDetail())) {
        await closeCredentialDetail(tester);
      }
      await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
      expect(findWalletCards(emailCredId), findsOneWidget);
      expect(
        walletCardCredentialIds(tester).where((id) => id == emailCredId),
        hasLength(1),
      );
      await navigateToCredentialDetailsPage(tester, emailCredId);

      // Expect the card to have the correct content again
      await evaluateIssuedEmailAddressCard();
    });

    testWidgets("delete-after-issuance", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await issueEmailAddress(tester, irmaBinding);

      // Press ok
      final okButtonFinder = find.text("OK");
      await tester.tapAndSettle(okButtonFinder);

      // Go to data tab.
      await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

      // Open the email card.
      const emailCredId = "irma-demo.sidn-pbdf.email";
      final emailTileFinder = findWalletCards(emailCredId);
      await navigateToCredentialDetailsPage(tester, emailCredId);

      // Press Delete in the detail view and confirm the dialog.
      await deleteCredentialFromDetail(tester);

      // Expect snackbar
      final snackbarFinder = find.byType(SnackBar);
      expect(snackbarFinder, findsOneWidget);

      // Expect the snackbar to contain the correct text
      final snackbarTextFinder = find.text(
        "Success! The data has been deleted.",
      );
      expect(snackbarTextFinder, findsOneWidget);

      // Expect to be back on the data tab
      final dataTabFinder = find.byType(DataTab);
      expect(dataTabFinder, findsOneWidget);

      // Expect the email tile to be gone
      expect(emailTileFinder, findsNothing);
    });
  });
}
