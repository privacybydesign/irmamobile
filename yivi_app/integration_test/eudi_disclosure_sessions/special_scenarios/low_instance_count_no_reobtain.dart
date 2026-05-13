import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";

/// Low-instance-count behavior for an OID4VCI credential.
///
/// Issues a single email cred via the staging `batch2-issuer`
/// (`batch_credential_issuance.batch_size = 2`). The wallet's
/// [`lowInstanceCountThreshold`](`credential_card_status.dart`) is 5, so 2
/// instances ≤ 5 immediately puts the cred in the `almostExpired` /
/// `isExpiringSoon` state.
///
/// Asserts (per `credential_card_status.dart:94-97`): because the cred has no
/// IssueURL (`hasValidIssueUrl == false`), `showReobtain` is false even with
/// `hasWarning == true` — so the details-screen card shows expiring-soon
/// styling but **no Reobtain button**, in contrast to the IRMA-side
/// `testLowCredentialInstanceCountShowsReobtainButton`.
Future<void> lowInstanceCountNoReobtainTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailViaOpenID4VCIBatch2(tester, irmaBinding);

  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await navigateToCredentialDetailsPage(tester, veramoEmailCredentialVct);

  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    instancesRemaining: 2,
    isExpiringSoon: true,
    expectReobtainButton: false,
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [("Email", "test@example.com"), ("Domain", "example.com")],
  );
}
