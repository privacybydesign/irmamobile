import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../eudi_choice_helpers.dart";

/// OR disjunction: verifier asks for email OR phone. Wallet has both.
/// Default selection is email; user opens change-choice, picks phone, and
/// shares. Asserts the chosen cred's instance count decremented and the
/// other cred's count is unchanged.
Future<void> discloseWithChoiceDisjunctionTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "test@example.com",
    domain: "example.com",
  );
  await issuePhoneViaOpenID4VCI(tester, irmaBinding, phoneNumber: "0612345678");

  final dcql = {
    "credentials": [
      {
        "id": "email-query",
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
      {
        "id": "phone-query",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoPhoneCredentialVct],
        },
        "claims": [
          {
            "path": ["phone_number"],
          },
        ],
      },
    ],
    "credential_sets": [
      {
        "options": [
          ["email-query"],
          ["phone-query"],
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await tester.waitFor(find.byType(DisclosureShareScreen));

  // Default selection is the email cred.
  final cardFinder = findCredentialCards();
  expect(cardFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardFinder,
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [("Email", "test@example.com")],
  );

  await tapChangeChoicesButton(tester);

  // 2 owned options; nothing to add for OID4VCI (the irmago backend leaves
  // `obtainable_options == null` for cred types without an IssueURL). Two
  // types: each row has the name, and "{value} · {issuer}" below it.
  expectOnlyOwnedInSheet(2);
  final emailRow = sheetOwnedRowsWith("test@example.com · Test Issuer");
  final phoneRow = sheetOwnedRowsWith("0612345678 · Test Issuer");
  expect(emailRow, findsOneWidget);
  expect(phoneRow, findsOneWidget);
  expect(
    find.descendant(
      of: emailRow,
      matching: find.text("Email Credential (SD-JWT)"),
    ),
    findsWidgets,
  );
  expect(
    find.descendant(
      of: phoneRow,
      matching: find.text("Phone Credential (SD-JWT)"),
    ),
    findsWidgets,
  );

  // Pick the phone (the sheet closes), share.
  await pickOwned(tester, "0612345678 · Test Issuer");
  await evaluateCredentialCard(
    tester,
    findShareSlot(0),
    issuerName: "Test Issuer",
    credentialName: "Phone Credential (SD-JWT)",
    attributes: [("Phone Number", "0612345678")],
  );
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
