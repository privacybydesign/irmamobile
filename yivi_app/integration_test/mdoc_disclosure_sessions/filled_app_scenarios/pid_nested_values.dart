import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 24: structured mdoc values on the permission screen. The PID's
/// `place_of_birth` is a map; it must unfold into the same nested rows the
/// credential card shows (a "Birth Place" group with `country` and
/// `locality`), and the tagged `birth_date` must read as a date, not as a
/// CBOR tag. irmago prerequisite: the disclosure preview flattens structured
/// values like the credential list does (docs/mdoc-integration-plan.md,
/// irmago prerequisite 3).
Future<void> pidNestedValuesTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issuePidMdoc(tester, irmaBinding);

  const dcql = """
{
  "credentials": [
    {
      "id": "pid",
      "format": "mso_mdoc",
      "meta": { "doctype_value": "eu.europa.ec.eudi.pid.1" },
      "claims": [
        { "path": ["eu.europa.ec.eudi.pid.1", "family_name"] },
        { "path": ["eu.europa.ec.eudi.pid.1", "birth_date"] },
        { "path": ["eu.europa.ec.eudi.pid.1", "place_of_birth"] }
      ]
    }
  ]
}
""";

  await startMdocDisclosure(tester, irmaBinding, dcql);

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  // Metadata order; sub-keys of the map alphabetical, labelled by their key
  // because the issuer publishes no display name below the element.
  const rows = [
    ("Family Name(s)", presetFamilyName),
    ("Birth Date", presetBirthDate),
    (
      "Birth Place",
      [("country", presetBirthCountry), ("locality", presetBirthLocality)],
    ),
  ];
  await evaluateCredentialCard(
    tester,
    cardsFinder,
    credentialName: pidMdocCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: rows,
  );

  // Selective disclosure: the given name was not requested.
  expect(find.text(presetGivenName, skipOffstage: false), findsNothing);

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
