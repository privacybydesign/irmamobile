import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";

/// Issues two emails; only one satisfies the DCQL `values` filter. The
/// matching cred is the sole option on the overview (the non-matching cred
/// is filtered out by the backend, and OID4VCI produces no obtainable
/// template), so no change-choice button is shown.
Future<void> valueOptionsOnePresentOneNotTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "one@example.com",
  );
  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "two@example.com",
  );

  final dcql = {
    "credentials": [
      {
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoEmailCredentialVct],
        },
        "claims": [
          {
            "id": "em",
            "path": ["email"],
            "values": ["two@example.com"],
          },
          {
            "id": "do",
            "path": ["domain"],
          },
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
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [
      ("Email", "two@example.com"),
      ("Domain", "example.com"),
    ],
  );

  // With one owned option and no obtainable template, the overview hides
  // the change-choice button.
  expect(find.text("Change choice"), findsNothing);

  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: "Email Credential (SD-JWT)",
        issuerName: "Test Issuer",
        attributes: [
          ("Email", "two@example.com"),
          ("Domain", "example.com"),
        ],
      ),
    ],
  );
}
