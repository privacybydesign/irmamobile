import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_make_choice_screen.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../eudi_disclosure_sessions/eudi_choice_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 21: two age-verification mdocs with different threshold sets (so
/// their hashes differ), both answering the same query. Candidate order is
/// chronological, oldest first; the default choice is the most recently
/// issued one (issuance counts as first use). The user switches to the older
/// one and shares it.
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

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  final overviewCard = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(overviewCard, findsOneWidget);

  // Default choice: the newest credential.
  await evaluateCredentialCard(
    tester,
    overviewCard,
    credentialName: avCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: [(avLabel(18), booleanYes), (avLabel(65), booleanYes)],
  );

  await tapChangeChoicesButton(tester);
  expect(find.byType(DisclosureMakeChoiceScreen), findsOneWidget);

  final choiceCardsFinder = find.descendant(
    of: find.byType(DisclosureMakeChoiceScreen),
    matching: find.byType(YiviCredentialCard),
    skipOffstage: false,
  );
  expect(choiceCardsFinder, findsNWidgets(2));

  // Oldest first, newest pre-selected.
  await evaluateCredentialCard(
    tester,
    choiceCardsFinder.at(0),
    attributes: [(avLabel(18), booleanYes), (avLabel(65), booleanNo)],
    isSelected: false,
  );
  await tester.scrollUntilVisible(choiceCardsFinder.at(1), 100);
  await evaluateCredentialCard(
    tester,
    choiceCardsFinder.at(1),
    attributes: [(avLabel(18), booleanYes), (avLabel(65), booleanYes)],
    isSelected: true,
  );

  // Switch to the older one, confirm, share.
  await tester.scrollUntilVisible(choiceCardsFinder.at(0), -100);
  await tester.tapAndSettle(choiceCardsFinder.at(0));
  await evaluateCredentialCard(
    tester,
    choiceCardsFinder.at(0),
    isSelected: true,
  );
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  await evaluateCredentialCard(
    tester,
    overviewCard,
    attributes: [(avLabel(18), booleanYes), (avLabel(65), booleanNo)],
  );
  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: avCredentialName,
        issuerName: eudiIssuerDisplayName,
        attributes: [(avLabel(18), booleanYes), (avLabel(65), booleanNo)],
      ),
    ],
  );
}
