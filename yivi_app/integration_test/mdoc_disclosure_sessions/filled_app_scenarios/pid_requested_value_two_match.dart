import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 20: a requested value with several acceptable values on a non-boolean
/// element. Three PID mdocs are issued (Amsterdam, Utrecht, Rotterdam); the
/// verifier accepts Amsterdam or Utrecht. Two match, so the change-choice
/// screen lists exactly those two, and the user can pick either.
Future<void> pidRequestedValueTwoMatchTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  for (final city in ["Amsterdam", "Utrecht", "Rotterdam"]) {
    await issuePidMdoc(
      tester,
      irmaBinding,
      data: pidMdocData(residentCity: city),
    );
  }

  const dcql = """
{
  "credentials": [
    {
      "id": "pid",
      "format": "mso_mdoc",
      "meta": { "doctype_value": "eu.europa.ec.eudi.pid.1" },
      "claims": [
        { "path": ["eu.europa.ec.eudi.pid.1", "family_name"] },
        {
          "path": ["eu.europa.ec.eudi.pid.1", "resident_city"],
          "values": ["Amsterdam", "Utrecht"]
        }
      ]
    }
  ]
}
""";

  await startMdocDisclosure(tester, irmaBinding, dcql);

  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  expect(findCredentialCards(skipOffstage: false), findsOneWidget);

  await changeChoice(tester, 0);
  // The two matching PIDs; the Rotterdam one is filtered out by irmago and
  // there is no addable template for an mdoc.
  final rows = findSheetOwnedRows();
  expect(rows, findsNWidgets(2));
  expect(findSheetAddRow("eu.europa.ec.eudi.pid.1"), findsNothing);
  expect(find.text("Rotterdam", skipOffstage: false), findsNothing);

  // Both rows lead with the family name ("Doe"), so go by position: oldest
  // first, the Amsterdam PID. Pick it explicitly; the sheet closes.
  await tester.tapAndSettle(rows.at(0));
  await tester.waitUntilDisappeared(findChoiceSheet());
  await evaluateCredentialCard(
    tester,
    findShareSlot(0),
    attributes: [("Family Name(s)", "Doe"), ("Resident City", "Amsterdam")],
  );
  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: pidMdocCredentialName,
        issuerName: eudiIssuerDisplayName,
        attributes: [("Family Name(s)", "Doe"), ("Resident City", "Amsterdam")],
      ),
    ],
  );
}
