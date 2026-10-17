import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../eudi_choice_helpers.dart";

/// OR disjunction across two cred types, each with two issued instances.
/// The change-choice screen exposes the four owned creds (no obtainable
/// templates — irmago leaves `obtainable_options == null` for OID4VCI cred
/// types). User selects one of the four owned options and proceeds.
Future<void> selectOneOfTwoEmailsAndTwoPhonesTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "one@example.com",
    domain: "example.com",
  );
  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "two@template.com",
    domain: "template.com",
  );
  await issuePhoneViaOpenID4VCI(tester, irmaBinding, phoneNumber: "0612345678");
  await issuePhoneViaOpenID4VCI(tester, irmaBinding, phoneNumber: "0687654321");

  final dcql = {
    "credentials": [
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
    ],
    "credential_sets": [
      {
        "options": [
          ["mail"],
          ["phone"],
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  await tapChangeChoicesButton(tester);

  // 4 owned options; nothing to add for OID4VCI. With two types in one
  // sheet, each row is the card with its values.
  expectOnlyOwnedInSheet(4);
  for (final value in [
    "one@example.com",
    "two@template.com",
    "0612345678",
    "0687654321",
  ]) {
    expect(sheetOwnedRowsWith("$value"), findsOneWidget);
  }

  // One tap picks the last phone and closes the sheet.
  await pickOwned(tester, "0687654321");
  await evaluateCredentialCard(
    tester,
    findShareSlot(0),
    issuerName: "Test Issuer",
    credentialName: "Phone Credential (SD-JWT)",
    attributes: [("Phone Number", "0687654321")],
  );

  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: "Phone Credential (SD-JWT)",
        issuerName: "Test Issuer",
        attributes: [("Phone Number", "0687654321")],
      ),
    ],
  );
}
