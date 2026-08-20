import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";

/// Issue an OrganizationCredentialSdJwt (which carries nested
/// `faculties[].departments[].courses[]` data) and disclose two top-level
/// claims (`name`, `founded`). Verifies that disclosure of an OID4VCI
/// credential whose underlying schema includes deeply nested data still
/// renders cleanly on the disclosure card when the request scopes to
/// top-level attributes.
///
/// The exhaustive nested-rendering path is already covered by
/// `openid4vci_issuance_test.dart::testIssueOrganizationOpenID4VCI`. This
/// test confirms the same credential type works as a *disclosure* target.
Future<void> discloseNestedOrganizationCredentialTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueOrganizationViaOpenID4VCI(tester, irmaBinding);

  final dcql = {
    "credentials": [
      {
        "id": "org-cred",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoOrganizationCredentialVct],
        },
        "claims": [
          {
            "id": "n",
            "path": ["name"],
          },
          {
            "id": "f",
            "path": ["founded"],
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
    credentialName: "Organization Credential (SD-JWT)",
    attributes: [("University Name", "TU Delft"), ("Founded", "1842")],
  );

  // The deeper structure must NOT leak into the disclosure card — selective
  // disclosure should not reveal a faculty name when the request only asks
  // for `name` and `founded`.
  expect(find.text("EEMCS"), findsNothing);
  expect(find.text("Architecture"), findsNothing);

  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: "Organization Credential (SD-JWT)",
        issuerName: "Test Issuer",
        attributes: [("University Name", "TU Delft"), ("Founded", "1842")],
      ),
    ],
  );
}
