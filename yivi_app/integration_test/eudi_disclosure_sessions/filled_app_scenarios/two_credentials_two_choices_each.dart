import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../eudi_choice_helpers.dart";

/// Issues 2 emails + 2 phones, requests email AND phone. Each card on the
/// share screen has a "Change" pill; each Change sheet shows exactly the two
/// owned options and nothing to add (irmago leaves
/// `obtainable_options == null` for OID4VCI cred types).
Future<void> twoCredentialsTwoChoicesEachTest(
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
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  // One card per requested credential, each with a Change pill.
  expect(findShareSlot(0), findsOneWidget);
  expect(findShareSlot(1), findsOneWidget);

  // Email sheet: two owned options only. Close it without changing.
  await tapChangeChoicesButton(tester, 0);
  expectOnlyOwnedInSheet(2);
  expect(sheetOwnedRowsWith("one@example.com"), findsOneWidget);
  expect(sheetOwnedRowsWith("two@template.com"), findsOneWidget);
  await closeChoiceSheet(tester);

  // Phone sheet: two owned options only. Close it without changing.
  await tapChangeChoicesButton(tester, 1);
  expectOnlyOwnedInSheet(2);
  expect(sheetOwnedRowsWith("0612345678"), findsOneWidget);
  expect(sheetOwnedRowsWith("0687654321"), findsOneWidget);
  await closeChoiceSheet(tester);

  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: "Email Credential (SD-JWT)",
        issuerName: "Test Issuer",
        attributes: [("Email", "one@example.com"), ("Domain", "example.com")],
      ),
      (
        credentialName: "Phone Credential (SD-JWT)",
        issuerName: "Test Issuer",
        attributes: [("Phone Number", "0612345678")],
      ),
    ],
  );
}
