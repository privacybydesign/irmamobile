import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";

/// At-zero-instance-count behavior for an OID4VCI credential.
///
/// Issues a single email cred via the staging `batch2-issuer` (batch_size = 2)
/// and discloses it twice to drain both instances. After the second disclosure
/// the cred has 0 remaining batch instances.
///
/// Asserts (per `credential_card_status.dart:94-97`): with
/// `instanceCount == 0` the cred is `isExpired`/danger-styled, but because
/// `hasValidIssueUrl == false` (no IssueURL on OID4VCI), `showReobtain`
/// remains false — the details-screen card has no Reobtain button.
///
/// (Note: per irmago's design, a third disclosure attempt against an
/// exhausted batch errors out before the wallet ever shows the disclosure
/// overview, so we don't assert disclosure-overview gating here.)
Future<void> zeroInstanceCountNoReobtainTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailViaOpenID4VCIBatch2(tester, irmaBinding);

  final dcql = {
    "credentials": [
      {
        "id": "email-cred",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoEmailCredentialVct],
        },
        "claims": [
          {"path": ["email"]},
        ],
      },
    ],
  };

  // Disclose twice to drain both batch instances. The introduction screen
  // is gated by a persisted preference and only renders on the first
  // disclosure of the session — on the second pass we land directly on the
  // overview, so we wait for that instead.
  for (var i = 0; i < 2; i++) {
    final sessionUrl = await startVeramoVPSession(dcql);
    irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
    if (i == 0) {
      await evaluateIntroduction(tester);
    }
    await tester.pumpUntilFound(find.byType(DisclosureChoicesOverview));
    await shareAndFinishEudiDisclosure(tester);
  }

  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await navigateToCredentialDetailsPage(tester, veramoEmailCredentialVct);

  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    instancesRemaining: 0,
    style: IrmaCardStyle.danger,
    isExpired: true,
    expectReobtainButton: false,
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [
      ("Email", "test@example.com"),
      ("Domain", "example.com"),
    ],
  );

  // Pop the credential-details sub-route so the bottom nav bar is visible
  // again — `verifyActivityLogCount` taps `nav_button_activity` which only
  // renders inside the home scaffold.
  await navigateBack(tester);

  // 1 issuance + 2 disclosures = 3 activity log entries.
  await verifyActivityLogCount(tester, 3);
}
