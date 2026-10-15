import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../eudi_choice_helpers.dart";

/// Issue two emails, then disclose. The Change sheet lists exactly the two
/// owned creds under "In your app" — nothing under "Not in your app yet"
/// (irmago leaves `obtainable_options == null` for OID4VCI cred types
/// because they have no `IssueURL`). The user picks the second one; one tap
/// selects it and closes the sheet.
Future<void> oneCredentialTwoChoicesTest(
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
            "path": ["email"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  // The default is the first owned email.
  await evaluateCredentialCard(
    tester,
    findShareSlot(0),
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [("Email", "one@example.com")],
  );

  await tapChangeChoicesButton(tester);

  // Two owned, told apart by their value; nothing to add for OID4VCI.
  expectOnlyOwnedInSheet(2);
  expect(sheetOwnedRowsWith("one@example.com"), findsOneWidget);
  expect(sheetOwnedRowsWith("two@template.com"), findsOneWidget);

  // Pick the second owned cred: the sheet closes, the share screen shows it.
  await pickOwned(tester, "two@template.com");
  await evaluateCredentialCard(
    tester,
    findShareSlot(0),
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [("Email", "two@template.com")],
  );

  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: "Email Credential (SD-JWT)",
        issuerName: "Test Issuer",
        attributes: [("Email", "two@template.com")],
      ),
    ],
  );
}
