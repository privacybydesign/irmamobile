import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../eudi_choice_helpers.dart";

/// DCQL `values` filter accepting a list of acceptable values. Issues three
/// emails (`one@`, `two@`, `three@`); verifier asks for email in
/// {one@example.com, three@example.com} plus domain. Two creds match.
Future<void> valueOptionsTwoMatchTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailViaOpenID4VCI(tester, irmaBinding, email: "one@example.com");
  await issueEmailViaOpenID4VCI(tester, irmaBinding, email: "two@example.com");
  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "three@example.com",
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
            "id": "em",
            "path": ["email"],
            "values": ["one@example.com", "three@example.com"],
          },
          {
            "id": "do",
            "path": ["domain"],
          },
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

  await evaluateCredentialCard(
    tester,
    cardsFinder,
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [("Email", "one@example.com"), ("Domain", "example.com")],
  );

  await tapChangeChoicesButton(tester);

  // Two matching owned creds, in this order; nothing to add for OID4VCI
  // (backend leaves `obtainable_options == null` because the cred type has
  // no IssueURL). The non-matching two@ is not offered.
  expectOnlyOwnedInSheet(2);
  final rows = findSheetOwnedRows();
  expect(
    find.descendant(of: rows.at(0), matching: find.text("one@example.com")),
    findsOneWidget,
  );
  expect(
    find.descendant(of: rows.at(1), matching: find.text("three@example.com")),
    findsOneWidget,
  );
  expect(sheetOwnedRowsWith("two@example.com"), findsNothing);

  // Keep the default (the first): close the sheet and share.
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
    ],
  );
}
