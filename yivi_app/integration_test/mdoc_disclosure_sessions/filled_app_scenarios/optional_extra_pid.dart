import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 23: the age-verification mdoc is required, the PID mdoc is optional
/// (`credential_sets` with `required: false`). Both are owned. The user adds
/// the optional PID from its sheet, sees it on the share screen, leaves it
/// out again, and shares only the age claim.
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

  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  final cardsFinder = findCredentialCards(skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  // Default selection is the required credential.
  await evaluateCredentialCard(
    tester,
    cardsFinder,
    credentialName: avCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: [(avLabel(18), booleanYes)],
  );

  // The optional PID is offered as a row to add; its sheet has the PID in
  // the app and nothing to add from Yivi (an mdoc has no issue URL).
  final optional = optionalItemIndex(tester);
  await addOptional(tester, optional);
  expect(find.text("Add optional data"), findsOneWidget);
  expect(findSheetOwnedRows(), findsOneWidget);
  expect(findSheetAddRow("eu.europa.ec.eudi.pid.1"), findsNothing);

  // One card of one type: the row leads with its first value. Picking it
  // includes the PID and closes the sheet.
  await pickOwned(tester, presetFamilyName);
  expect(cardsFinder, findsNWidgets(2));
  final pidSlot = findShareSlot(optional);
  await tester.scrollUntilVisible(pidSlot, 100);
  await evaluateCredentialCard(
    tester,
    pidSlot,
    credentialName: pidMdocCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: [("Family Name(s)", presetFamilyName)],
  );

  // Leave the optional PID out again and share only the age claim.
  await removeOptional(tester, optional);
  expect(
    find.byKey(Key("share_add_optional_$optional"), skipOffstage: false),
    findsOneWidget,
  );
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
