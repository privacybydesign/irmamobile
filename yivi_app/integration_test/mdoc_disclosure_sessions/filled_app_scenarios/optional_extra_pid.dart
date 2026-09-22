import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_make_choice_screen.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 23: the age-verification mdoc is required, the PID mdoc is optional
/// (`credential_sets` with `required: false`). Both are owned. The user adds
/// the optional PID, sees it on the overview, removes it again, and shares
/// only the age claim.
Future<void> optionalExtraPidTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueAvMdoc(tester, irmaBinding);
  await issuePidMdoc(tester, irmaBinding);

  const dcql = """
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
        { "path": ["eu.europa.ec.eudi.pid.1", "family_name"] }
      ]
    }
  ],
  "credential_sets": [
    { "required": false, "options": [["pid"]] },
    { "options": [["age"]] }
  ]
}
""";

  await startMdocDisclosure(tester, irmaBinding, dcql);

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  // Default selection is the required credential.
  await evaluateCredentialCard(
    tester,
    cardsFinder,
    credentialName: avCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: [(avLabel(18), booleanYes)],
  );

  final addOptionalDataButton = find.text("Add optional data");
  await tester.scrollUntilVisible(addOptionalDataButton, 100);
  expect(addOptionalDataButton, findsOneWidget);
  await tester.tapAndSettle(addOptionalDataButton);

  expect(find.byType(DisclosureMakeChoiceScreen), findsOneWidget);
  final choiceCardsFinder = find.descendant(
    of: find.byType(DisclosureMakeChoiceScreen),
    matching: find.byType(YiviCredentialCard),
    skipOffstage: false,
  );
  expect(choiceCardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    choiceCardsFinder,
    credentialName: pidMdocCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: [("Family Name(s)", presetFamilyName)],
  );
  expect(find.text("Obtain new data"), findsNothing);

  // Confirm: the overview now shows the age mdoc and the PID.
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
  expect(cardsFinder, findsNWidgets(2));
  await tester.scrollUntilVisible(cardsFinder.at(1), 100);
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: pidMdocCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: [("Family Name(s)", presetFamilyName)],
  );

  // Remove the optional PID again and share only the age claim.
  await tester.tapAndSettle(
    find.byKey(const Key("remove_optional_data_button")),
  );
  expect(addOptionalDataButton, findsOneWidget);
  expect(cardsFinder, findsOneWidget);

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
}
