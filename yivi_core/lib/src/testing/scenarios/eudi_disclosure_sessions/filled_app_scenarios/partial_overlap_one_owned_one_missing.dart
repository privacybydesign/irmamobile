import "package:flutter_test/flutter_test.dart";

import "../../../../screens/home/home_screen.dart";
import "../../../../screens/session/session_screen.dart";
import "../../../../screens/session/widgets/issue_during_disclosure_screen.dart";
import "../../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../helpers/eudi_issuance_helpers.dart";
import "../../../helpers/helpers.dart";
import "../../../irma_binding.dart";
import "../../../util.dart";
import "../../disclosure_session/disclosure_helpers.dart";

/// Wallet has email; verifier asks for email AND phone. Backend hides the
/// `DisclosureChoicesOverview` whenever any issuance step exists, so the
/// wallet renders `IssueDuringDisclosureScreen` with the missing phone
/// descriptor — the owned email is **not visible at this stage**.
///
/// On the IRMA-issued spine, the user could tap "Obtain data" to issue the
/// missing phone in-flow. For OID4VCI the same descriptor has no `IssueURL`
/// so the wallet shows a "Close" CTA instead. The session can only be
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
  await evaluateIntroduction(tester);
  await tester.pumpAndSettle();

  expect(find.byType(IssueDuringDisclosureScreen), findsOneWidget);

  // The missing phone descriptor card renders, with name from VCT metadata.
  // Direct text-finder used because the missing-cred descriptor has no logo
  // (the avatar shows initials "P"), and the bridge payload returns
  // `issuer.name == null` — see cred_missing.dart for details.
  final cardFinder = find.byType(YiviCredentialCard);
  expect(cardFinder, findsOneWidget);
  expect(
    find.descendant(
      of: cardFinder,
      matching: find.text("Phone Credential (SD-JWT)"),
    ),
    findsOneWidget,
  );

  // The owned email is intentionally not visible — backend hides the
  // choices overview while issuance steps exist.
  expect(find.text("test@example.com"), findsNothing);

  // No "Obtain data" CTA. The bottom-bar primary is "Close" because the
  // missing cred has no IssueURL.
  expect(find.text("Obtain data"), findsNothing);
  expect(find.text("Close"), findsOneWidget);

  await tester.tapAndSettle(find.text("Close"));

  // Wait for the SessionScreen to unmount before ending the test.
  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  // No disclosure log was written; only the prior issuance entry remains.
  await verifyActivityLogCount(tester, 1);
}
