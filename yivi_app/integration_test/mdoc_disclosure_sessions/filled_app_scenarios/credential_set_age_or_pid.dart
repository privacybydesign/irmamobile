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

/// Test 22: a DCQL credential set offering two ways to satisfy one pick-one:
/// the age-verification mdoc's `age_over_18`, or the PID mdoc's birth date.
///
/// First run: only the age mdoc is owned, so it is pre-selected and shared.
/// Second run: the PID is issued as well; the change-choice screen offers
/// both, the user picks the PID and shares that.
Future<void> credentialSetAgeOrPidTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueAvMdoc(tester, irmaBinding);

  // Only the age mdoc owned: it is the selection.
  await startMdocDisclosure(tester, irmaBinding, _ageOrPidDcql);
  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  final overviewCards = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(overviewCards, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    overviewCards,
    credentialName: avCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: [(avLabel(18), booleanYes)],
  );
  await shareAndFinishEudiDisclosure(tester);
  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: avCredentialName,
        issuerName: eudiIssuerDisplayName,
        attributes: [(avLabel(18), booleanYes)],
      ),
    ],
  );

  // Both owned: choose the PID instead.
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await issuePidMdoc(tester, irmaBinding);

  await startMdocDisclosure(tester, irmaBinding, _ageOrPidDcql);
  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  expect(overviewCards, findsOneWidget);

  await tapChangeChoicesButton(tester);
  expect(find.byType(DisclosureMakeChoiceScreen), findsOneWidget);
  final choiceCardsFinder = find.descendant(
    of: find.byType(DisclosureMakeChoiceScreen),
    matching: find.byType(YiviCredentialCard),
    skipOffstage: false,
  );
  expect(choiceCardsFinder, findsAtLeast(2));

  final pidCard = find.ancestor(
    of: find.text("Birth Date", skipOffstage: false),
    matching: find.byType(YiviCredentialCard),
  );
  await tester.scrollUntilVisible(pidCard, 100);
  await tester.tapAndSettle(pidCard);
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  await evaluateCredentialCard(
    tester,
    overviewCards,
    credentialName: pidMdocCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: [("Birth Date", presetBirthDate)],
  );
  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: pidMdocCredentialName,
        issuerName: eudiIssuerDisplayName,
        attributes: [("Birth Date", presetBirthDate)],
      ),
    ],
  );
}

const _ageOrPidDcql = """
{
  "credentials": [
    {
      "id": "age",
      "format": "mso_mdoc",
      "meta": { "doctype_value": "eu.europa.ec.av.1" },
      "claims": [
        { "path": ["eu.europa.ec.av.1", "age_over_18"] }
      ]
    },
    {
      "id": "pid",
      "format": "mso_mdoc",
      "meta": { "doctype_value": "eu.europa.ec.eudi.pid.1" },
      "claims": [
        { "path": ["eu.europa.ec.eudi.pid.1", "birth_date"] }
      ]
    }
  ],
  "credential_sets": [
    { "options": [["age"], ["pid"]] }
  ]
}
""";
