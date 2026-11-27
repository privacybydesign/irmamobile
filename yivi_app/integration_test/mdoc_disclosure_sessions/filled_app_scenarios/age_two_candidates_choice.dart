import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/disclosure/disclosure_flow.dart";

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
/// The order is irmago's (issue #804, `SortCandidates`): usable first, then
/// most uses left, then valid longest. These two cards tie on all three, so
/// they keep the order they were issued in, and the default is the first:
/// nothing was shared with this verifier before.
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

  expect(find.byType(DisclosureFlow), findsOneWidget);
  final overviewCard = findCredentialCards(skipOffstage: false);
  await openChangePage(tester);
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

  // Switch to the newer one: a tap selects it, "Choose" applies it.
  await tester.tapAndSettle(rows.at(1));
  await chooseInSheet(tester);

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
