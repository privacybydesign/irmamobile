import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../eudi_choice_helpers.dart";

/// DCQL claim_sets — verifier offers two satisfying claim sets:
///   1. email-cond: email == "one@example.com"
///   2. domain-cond: domain == "template.com" + email-general (any email)
/// Wallet has three emails, two of which satisfy a claim set. Asserts the
/// first satisfying credential is preselected and that the Change
/// sheet lists exactly the two matching owned credentials.
///
/// Unlike the IRMA-issued SD-JWT spine, the sheet has no "Not in your app
/// yet" part: the irmago backend leaves `obtainable_options == null` for
/// OID4VCI credential types because they carry no `IssueURL`.
Future<void> claimSetsPickFirstSatisfyingTest(
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
  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "three@not.com",
    domain: "not.com",
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
            "id": "email-cond",
            "path": ["email"],
            "values": ["one@example.com"],
          },
          {
            "id": "domain-cond",
            "path": ["domain"],
            "values": ["template.com"],
          },
          {
            "id": "email-general",
            "path": ["email"],
          },
        ],
        "claim_sets": [
          ["email-cond"],
          ["domain-cond", "email-general"],
        ],
      },
    ],
  };
  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  expect(findCredentialCards(skipOffstage: false), findsOneWidget);

  await tapChangeChoicesButton(tester);

  // Two owned (matching emails), in this order, and nothing to add.
  expectOnlyOwnedInSheet(2);
  final rows = findSheetOwnedRows();
  expect(
    find.descendant(of: rows.at(0), matching: find.text("one@example.com")),
    findsOneWidget,
  );
  expect(
    find.descendant(of: rows.at(1), matching: find.text("two@template.com")),
    findsOneWidget,
  );

  // Keep the default (the first): close the sheet and share.
  await closeChoiceSheet(tester);
  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: "Email Credential (SD-JWT)",
        issuerName: "Test Issuer",
        attributes: [("Email", "one@example.com")],
      ),
    ],
  );
}
