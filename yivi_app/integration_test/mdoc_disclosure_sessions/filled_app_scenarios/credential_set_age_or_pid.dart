import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
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
/// Second run: the PID is issued as well; the Change sheet offers both, the
/// user picks the PID and shares that.
Future<void> credentialSetAgeOrPidTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueAvMdoc(tester, irmaBinding);

  // Only the age mdoc owned: it is the selection.
  await startMdocDisclosure(tester, irmaBinding, _ageOrPidDcql);
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  final overviewCards = findCredentialCards(skipOffstage: false);
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

  // Both owned: choose the PID instead. The activity check above leaves us on
  // the pushed ActivityDetailsScreen, which has no bottom nav bar, so close
  // it (Done) before switching to the data tab.
  await tester.tapAndSettle(find.byKey(const Key("activity_detail_done")));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await issuePidMdoc(tester, irmaBinding);

  await startMdocDisclosure(tester, irmaBinding, _ageOrPidDcql);
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  expect(overviewCards, findsOneWidget);

  // The Change sheet offers both cards in the app; pick the PID. One tap
  // selects it and closes the sheet.
  await changeChoice(tester, 0);
  expect(findSheetOwnedRows(), findsNWidgets(2));
  await pickOwned(tester, pidMdocCredentialName);

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
