import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../eudi_choice_helpers.dart";

/// Required: phone. Optional: email. Wallet has both. Tests the "Add
/// optional data" flow on the choices overview. The change-choice screen
/// shows only the two owned email cards (no obtainable template — irmago
/// leaves `obtainable_options == null` for OID4VCI cred types).
Future<void> optionalExtraCredentialTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailViaOpenID4VCI(tester, irmaBinding, email: "one@example.com");
  await issueEmailViaOpenID4VCI(tester, irmaBinding, email: "two@example.com");
  await issuePhoneViaOpenID4VCI(tester, irmaBinding, phoneNumber: "0612345678");

  final dcql = {
    "credentials": [
      {
        "id": "phone",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoPhoneCredentialVct],
        },
        "claims": [
          {
            "id": "mn",
            "path": ["phone_number"],
          },
        ],
      },
      {
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoEmailCredentialVct],
        },
        "claims": [
          {
            "id": "em",
            "path": ["email"],
          },
          {
            "id": "do",
            "path": ["domain"],
          },
        ],
      },
    ],
    "credential_sets": [
      {
        "required": false,
        "options": [
          ["mail"],
        ],
      },
      {
        "options": [
          ["phone"],
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  final cardsFinder = findCredentialCards(skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  // Default selection is the required cred (phone).
  await evaluateCredentialCard(
    tester,
    cardsFinder,
    issuerName: "Test Issuer",
    credentialName: "Phone Credential (SD-JWT)",
    attributes: [("Phone Number", "0612345678")],
  );

  // The optional email is not shared yet: a row that opens its sheet.
  final optional = keyIndex(tester, "share_add_optional_");
  await openOptionalSheet(tester, optional);
  expect(find.text("Do you want to share this too?"), findsOneWidget);

  // Two owned email cards; nothing to add for OID4VCI.
  expectOnlyOwnedInSheet(2);
  expect(sheetOwnedRowsWith("one@example.com"), findsOneWidget);
  expect(sheetOwnedRowsWith("two@example.com"), findsOneWidget);

  // One tap includes the first and closes the sheet.
  await pickOwned(tester, "one@example.com");

  // Overview now shows two cards: phone + chosen email.
  expect(cardsFinder, findsNWidgets(2));
  await tester.scrollUntilVisible(cardsFinder.at(1), 100);
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [("Email", "one@example.com"), ("Domain", "example.com")],
  );

  // Leave the optional card out again: the add row is back.
  await removeOptional(tester, optional);
  expect(find.byKey(Key("share_add_optional_$optional")), findsOneWidget);
  expect(cardsFinder, findsOneWidget);

  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: "Phone Credential (SD-JWT)",
        issuerName: "Test Issuer",
        attributes: [("Phone Number", "0612345678")],
      ),
    ],
  );
}
