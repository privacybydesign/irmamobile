import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/data/schemaless_credentials_details_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/screens/session/widgets/success_graphic.dart";
import "package:yivi_core/src/widgets/credential_card/delete_credential_confirmation_dialog.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

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
      Locale locale, {
      required List<String> titles,
      required List<String> headerTexts,
    }) async {
      await pumpAndUnlockApp(
        tester,
        irmaBinding.repository,
        defaultLanguage: locale,
      );

      await issueMunicipalityPersonalData(tester, irmaBinding, locale: locale);
      await tester.pumpAndSettle();

      final successScreenFinder = find.byType(IssuanceSuccessScreen);
      expect(successScreenFinder, findsOneWidget);

      // Expect the SuccessGraphic in the IssuanceSuccessScreen
      final successGraphicFinder = find.byType(SuccessGraphic);
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

      // Expect CredentialTypeTile and tap it
      var categoryTileFinder = find
          .byKey(const Key("irma-demo.gemeente.personalData_tile"))
          .hitTestable();
      await tester.scrollUntilVisible(categoryTileFinder, 75);
      await tester.tapAndSettle(categoryTileFinder);

      // Expect detail page
      expect(find.byType(SchemalessCredentialsDetailsScreen), findsOneWidget);

      // Expect to find a card
      final credentialCardFinder = find.byType(YiviCredentialCard);
      expect(credentialCardFinder, findsOneWidget);

      // issueCredentials leaves out what the profile header and age row draw,
      // so check those here. The Dutch Ja/Nee age flags get no age row.
      evaluateCardSections(
        tester,
        credentialCardFinder,
        titles: titles,
        texts: headerTexts,
      );
    }

    testWidgets(
      "issue-municipality-en",
      (tester) => testIssueMunicipality(
        tester,
        const Locale("en", "EN"),
        titles: ["PERSON", "NAME", "REGISTRATION"],
        headerTexts: [
          "Willeke Liselotte de Bruijn",
          "10-04-1965",
          "Arnhem, Arnhem",
          "Dutch",
          "V",
          "Older than 21",
          "Not older than 65",
        ],
      ),
    );

    testWidgets(
      "issue-municipality-nl",
      (tester) => testIssueMunicipality(
        tester,
        const Locale("nl", "NL"),
        titles: ["PERSOON", "NAAM", "REGISTRATIE"],
        headerTexts: [
          "Willeke Liselotte de Bruijn",
          "10-04-1965",
          "Arnhem, Arnhem",
          "Nederlands",
          "V",
        ],
      ),
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

      // Press the email tile.
      final emailTileFinder = find.byKey(
        const Key("irma-demo.sidn-pbdf.email_tile"),
      );
      await tester.scrollUntilVisible(emailTileFinder, 75);
      await tester.tapAndSettle(emailTileFinder);

      // Expect the detail screen
      expect(find.byType(SchemalessCredentialsDetailsScreen), findsOneWidget);

      // Expect that it has one card.
      final credentialCardsFinder = find.byType(YiviCredentialCard);
      expect(credentialCardsFinder, findsOneWidget);

      // Expect the card to have the correct content
      final credentialCardFinder = credentialCardsFinder.first;

      Future<void> evaluateIssuedEmailAddressCard() => evaluateCredentialCard(
        tester,
        credentialCardFinder,
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

      // Expect the detail screen with one card again
      await tester.tapAndSettle(emailTileFinder);
      expect(find.byType(SchemalessCredentialsDetailsScreen), findsOneWidget);
      expect(credentialCardsFinder, findsOneWidget);

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

      // Press the email tile.
      final emailTileFinder = find.byKey(
        const Key("irma-demo.sidn-pbdf.email_tile"),
      );
      await tester.scrollUntilVisible(emailTileFinder, 75);
      await tester.tapAndSettle(emailTileFinder);

      // Open the bottom sheet
      final bottomSheetButtonFinder = find.byIcon(Icons.more_horiz_sharp);
      await tester.tapAndSettle(bottomSheetButtonFinder);

      // Press the delete button
      final deleteButtonFinder = find.text("Delete data");
      await tester.tapAndSettle(deleteButtonFinder);

      // Expect the delete confirmation dialog
      final deleteConfirmationDialogFinder = find.byType(
        DeleteCredentialConfirmationDialog,
      );
      expect(deleteConfirmationDialogFinder, findsOneWidget);

      // Press the delete button in the dialog
      final dialogDeleteButtonFinder = find.text("Delete");
      await tester.tapAndSettle(dialogDeleteButtonFinder);

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

    // The enablenow amounts carry displayHint="currency:EUR" in the irma-demo
    // scheme. irmago passes the hint on with each value, and the app formats
    // the amount for its language; attributes without a hint stay as issued.
    testWidgets("currency-display-hint", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      await startIssuanceSession(
        irmaBinding,
        groupAttributes(_incomeAttributes),
      );
      await tester.waitFor(find.byType(IssuancePermission));

      // The rows run past the bottom of the screen.
      final card = find.byType(YiviCredentialCard, skipOffstage: false);
      Finder inCard(String text) => find.descendant(
        of: card,
        matching: find.text(text, skipOffstage: false),
      );

      expect(inCard("€2,450.00"), findsOneWidget);
      expect(inCard("€1,325.00"), findsOneWidget);
      expect(inCard("€310.00"), findsOneWidget);
      expect(inCard("-€75.00"), findsOneWidget);
      // rent and pensionother.
      expect(inCard("€0.00"), findsNWidgets(2));
      expect(inCard("2450"), findsNothing);

      // No display hint: shown as issued.
      expect(inCard("12"), findsOneWidget);
      expect(inCard("2025-10-01"), findsOneWidget);
      expect(inCard("2026-09-30"), findsOneWidget);

      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
      await tester.waitUntilDisappeared(find.byType(IssuancePermission));
    });
  });
}

const _incomeCredentialId = "irma-demo.enablenow.income";

const _incomeAttributes = {
  "$_incomeCredentialId.rent": "0",
  "$_incomeCredentialId.salary": "2450",
  "$_incomeCredentialId.pensionstate": "1325",
  "$_incomeCredentialId.pensionprivate": "310",
  "$_incomeCredentialId.pensionother": "0",
  "$_incomeCredentialId.other": "-75",
  "$_incomeCredentialId.months": "12",
  "$_incomeCredentialId.periodstart": "2025-10-01",
  "$_incomeCredentialId.periodend": "2026-09-30",
};
