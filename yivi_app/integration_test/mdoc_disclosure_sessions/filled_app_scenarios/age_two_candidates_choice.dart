import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 21: two age-verification mdocs with different threshold sets (so
/// their hashes differ), both answering the same query. Candidate order is
/// chronological, oldest first, and the default choice is the first candidate.
/// The user switches to the other one and shares it.
///
/// TODO(#657): the default should be the most recently issued candidate
/// (issuance counts as first use), which would make the newest one
/// pre-selected here. irmago owns that policy and does not express it yet --
/// there is no recency signal in the disclosure plan, and both candidates
/// carry the same issuance_date -- so the app falls back to the first owned
/// option. When #657 lands, the two selection expectations below and the
/// shared candidate flip over.
Future<void> ageTwoCandidatesChoiceTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  // Older: not over 65. Newer: over 65 (test data, not Jane Doe's age).
  await issueAvMdoc(tester, irmaBinding, thresholds: {18: true, 65: false});
  await issueAvMdoc(tester, irmaBinding, thresholds: {18: true, 65: true});

  const dcql = """
{
  "credentials": [
    {
      "id": "age",
      "format": "mso_mdoc",
      "meta": { "doctype_value": "eu.europa.ec.av.1" },
      "claims": [
        { "path": ["eu.europa.ec.av.1", "age_over_18"] },
        { "path": ["eu.europa.ec.av.1", "age_over_65"] }
      ]
    }
  ]
}
""";

  await startMdocDisclosure(tester, irmaBinding, dcql);

  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  final overviewCard = findCredentialCards(skipOffstage: false);
  expect(overviewCard, findsOneWidget);

  // Default choice: the first (oldest) candidate.
  await evaluateCredentialCard(
    tester,
    overviewCard,
    credentialName: avCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: [(avLabel(18), booleanYes), (avLabel(65), booleanNo)],
  );

  // The Change sheet: both cards are in the app.
  await changeChoice(tester, 0);
  final rows = findSheetOwnedRows();
  expect(rows, findsNWidgets(2));
  expect(findSheetAddRow("eu.europa.ec.av.1"), findsNothing);

  // Oldest first, and the first one is pre-selected.
  expect(isSheetRowSelected(tester, rows.at(0)), isTrue);
  expect(isSheetRowSelected(tester, rows.at(1)), isFalse);

  // Switch to the newer one: one tap picks it and closes the sheet.
  await tester.tapAndSettle(rows.at(1));
  await tester.waitUntilDisappeared(findChoiceSheet());

  await evaluateCredentialCard(
    tester,
    overviewCard,
    attributes: [(avLabel(18), booleanYes), (avLabel(65), booleanYes)],
  );
  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: avCredentialName,
        issuerName: eudiIssuerDisplayName,
        attributes: [(avLabel(18), booleanYes), (avLabel(65), booleanYes)],
      ),
    ],
  );
}
