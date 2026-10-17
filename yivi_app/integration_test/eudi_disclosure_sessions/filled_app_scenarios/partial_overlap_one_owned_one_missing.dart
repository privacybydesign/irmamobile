import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";

/// Wallet has email; verifier asks for email AND phone. The backend sends
/// the choices together with the issuance step, so the share screen shows
/// the owned email in place and an empty spot for the missing phone.
///
/// On the IRMA-issued spine, the user could add the missing phone from the
/// app. For OID4VCI the same descriptor has no `IssueURL`, so the share
/// button is "Close" (with why above it). The session can only be
/// dismissed.
Future<void> partialOverlapOneOwnedOneMissingTest(
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
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoEmailCredentialVct],
        },
        "claims": [
          {
            "path": ["email"],
          },
        ],
      },
      {
        "id": "phone",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoPhoneCredentialVct],
        },
        "claims": [
          {
            "path": ["phone_number"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  // The owned email in place, the missing phone an empty spot with its
  // name from VCT metadata. The bridge payload returns `issuer.name ==
  // null` — see cred_missing.dart.
  expect(findShareSlot(0), findsOneWidget);
  expect(find.text("test@example.com"), findsOneWidget);
  expectEmptySpot(1, "Phone Credential (SD-JWT)");

  // "Close", because the missing cred has no IssueURL, and why.
  expectCannotAdd(tester, 1);
  await tapShare(tester);

  // Wait for the SessionScreen to unmount before ending the test.
  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  // No disclosure log was written; only the prior issuance entry remains.
  await verifyActivityLogCount(tester, 1);
}
