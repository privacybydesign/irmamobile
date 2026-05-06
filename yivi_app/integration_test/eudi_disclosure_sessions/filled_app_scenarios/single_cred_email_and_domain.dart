import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";

/// Issues an OID4VCI email credential, then asks the verifier for both
/// `email` and `domain`. Both values must render on the disclosure card.
Future<void> singleCredEmailAndDomainTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "test@example.com",
    domain: "example.com",
  );

  final dcql = {
    "credentials": [
      {
        "id": "email-cred",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoEmailCredentialVct],
        },
        "claims": [
          {"id": "em", "path": ["email"]},
          {"id": "do", "path": ["domain"]},
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);

  await evaluateIntroduction(tester);
  await tester.pumpAndSettle();

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  await evaluateCredentialCard(
    tester,
    cardsFinder,
    credentialName: "Email Credential (SD-JWT)",
    issuerName: "Test Issuer",
    attributes: [
      ("Email", "test@example.com"),
      ("Domain", "example.com"),
    ],
  );

  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: "Email Credential (SD-JWT)",
        issuerName: "Test Issuer",
        attributes: [
          ("Email", "test@example.com"),
          ("Domain", "example.com"),
        ],
      ),
    ],
  );
}
