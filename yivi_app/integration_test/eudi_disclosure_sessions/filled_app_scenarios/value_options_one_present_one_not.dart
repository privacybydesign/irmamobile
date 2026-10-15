import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

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
  await issueEmailViaOpenID4VCI(tester, irmaBinding, email: "one@example.com");
  await issueEmailViaOpenID4VCI(tester, irmaBinding, email: "two@example.com");

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
  await waitForRequest(tester);

  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  final cardsFinder = findCredentialCards(skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  await evaluateCredentialCard(
    tester,
    cardsFinder,
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [("Email", "two@example.com"), ("Domain", "example.com")],
  );

  // With one owned option and nothing to add, there is no Change pill.
  expect(find.byKey(const Key("share_change_0")), findsNothing);
  expect(find.text("Change"), findsNothing);

  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: "Email Credential (SD-JWT)",
        issuerName: "Test Issuer",
        attributes: [("Email", "two@example.com"), ("Domain", "example.com")],
      ),
    ],
  );
}
