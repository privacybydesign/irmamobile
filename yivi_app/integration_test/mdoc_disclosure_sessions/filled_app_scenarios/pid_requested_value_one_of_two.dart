import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 19: a requested value on a non-boolean element. Two PID mdocs are
/// issued, resident in Amsterdam and in Rotterdam; the verifier accepts a
/// resident city of Amsterdam or Utrecht. Only the Amsterdam PID is a
/// candidate, so it is the sole option and there is no change-choice button.
Future<void> pidRequestedValueOneOfTwoTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issuePidMdoc(
    tester,
    irmaBinding,
    data: pidMdocData(residentCity: "Amsterdam"),
  );
  await issuePidMdoc(
    tester,
    irmaBinding,
    data: pidMdocData(residentCity: "Rotterdam"),
  );

  await startMdocDisclosure(tester, irmaBinding, _pidResidentCityDcql);

  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  final cardsFinder = findCredentialCards(skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  const rows = [("Family Name(s)", "Doe"), ("Resident City", "Amsterdam")];
  await evaluateCredentialCard(
    tester,
    cardsFinder,
    credentialName: pidMdocCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: rows,
  );
  expect(find.text("Rotterdam", skipOffstage: false), findsNothing);
  // One candidate: nothing to change.
  expect(
    find.byKey(const Key("share_change_0"), skipOffstage: false),
    findsNothing,
  );

  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: pidMdocCredentialName,
        issuerName: eudiIssuerDisplayName,
        attributes: rows,
      ),
    ],
  );
}

const _pidResidentCityDcql = """
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
