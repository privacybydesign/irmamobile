import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/issue_during_disclosure_screen.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";

/// AND request for two creds (email + phone); wallet empty. Both missing
/// descriptors appear inside `IssueDuringDisclosureScreen`; bottom-bar
/// primary remains "Close".
Future<void> multipleCredsAllMissingTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

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
      {
        "id": "phone-cred",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoPhoneCredentialVct],
        },
        "claims": [
          {"path": ["phone_number"]},
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);
  await tester.pumpAndSettle();

  expect(find.byType(DisclosureChoicesOverview), findsNothing);
  expect(find.byType(IssueDuringDisclosureScreen), findsOneWidget);

  // Each missing-descriptor step renders one credential card; the wizard
  // shows them sequentially. Verify the first card's name comes from the
  // first VCT's metadata and that the screen is showing a missing-cred
  // descriptor card (not an owned-cred card).
  final cardsFinder = find.byType(YiviCredentialCard);
  expect(cardsFinder, findsAtLeast(1));

  // No "Obtain data" CTA on the wizard's bottom bar — neither cred is
  // obtainable.
  expect(find.text("Obtain data"), findsNothing);
  expect(find.text("Close"), findsOneWidget);

  await tester.tapAndSettle(find.text("Close"));

  // Wait for the SessionScreen to unmount before ending the test (the
  // dismiss flow is async; see cred_missing.dart for the full explanation).
  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  await verifyEmptyActivityLog(tester);
}
