import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";

/// Verifier asks for an OID4VCI email credential the wallet has never seen.
///
/// Backend (`irmago/internal/sessiontest/openid4vp_veramo_disclosure_test.go:
/// testVeramoVerifierRequestingMissingCredentialSurfacesIt`) populates
/// `IssueDuringDisclosure.Steps[0].Options[0]` with `IssueURL == nil` and
/// the descriptor's `Name`/`Issuer.Name` from VCT type metadata, and sends
/// the choices too, the missing one without owned options.
///
/// The share screen therefore shows an empty spot. Because the descriptor
/// has no IssueURL, it cannot be added from Yivi: the spot says so, and the
/// share button is "Close", with why above it. Tapping Close dismisses the
/// session.
Future<void> credMissingTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // No issuance — wallet has nothing.

  final dcql = {
    "credentials": [
      {
        "id": "email-cred",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoEmailCredentialVct],
        },
        "claims": [
          {
            "id": "em",
            "path": ["email"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  // One empty spot, named from VCT type metadata. The bridge payload
  // returns `issuer.name == null` for missing-cred descriptors, so no issuer
  // assertion is meaningful here.
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  expectEmptySpot(0, "Email Credential (SD-JWT)");
  expect(findEmptySpot(1), findsNothing);

  // Nothing to add it from — the cred type has no IssueURL; "Close", and
  // why.
  expectCannotAdd(tester, 0);
  await tapShare(tester);

  // The dismiss flow is async (dispatch → backend → state update → pop);
  // wait for the SessionScreen to fully unmount before ending the test so
  // the next test's setUp doesn't race against this widget tree's dispose.
  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  await verifyEmptyActivityLog(tester);
}
