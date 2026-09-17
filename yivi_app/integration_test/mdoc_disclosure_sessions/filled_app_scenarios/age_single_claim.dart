import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/requestor_header.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 14: the happy path. An age-verification mdoc is issued, the verifier
/// asks for `age_over_18` only. The permission screen names the verifier as a
/// vouched party, shows the one claim as "Yes" and nothing else, the share
/// succeeds, the verifier reports the presentation received, and the activity
/// log records the claim.
Future<void> ageSingleClaimTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueAvMdoc(tester, irmaBinding);

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
    }
  ]
}
""";

  final session = await startMdocDisclosure(tester, irmaBinding, dcql);

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  await evaluateRequestorHeader(
    tester,
    find.byType(RequestorHeader),
    localizedRequestorName: eudiVerifierDisplayName,
    isVerified: true,
  );

  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder,
    credentialName: avCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: [(avLabel(18), booleanYes)],
  );

  // Selective disclosure: the other thresholds the credential carries are not
  // on the card.
  expect(find.text(avLabel(65)), findsNothing);

  await shareAndFinishEudiDisclosure(tester);

  expect(
    await awaitVerifierResponse(session),
    isNotNull,
    reason: "the verifier should hold the wallet's presentation",
  );

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
