import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";

/// AND request for two creds (email + phone); wallet empty. Both missing
/// descriptors are empty spots on the share screen. Neither can be added,
/// so the button is "Close".
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
          {
            "path": ["email"],
          },
        ],
      },
      {
        "id": "phone-cred",
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

  // One empty spot per missing credential.
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  expect(findEmptySpot(0), findsOneWidget);
  expect(findEmptySpot(1), findsOneWidget);

  // Neither cred can be added; "Close", and why.
  expectCannotAdd(tester, 0);
  expect(
    find.descendant(
      of: findEmptySpot(1),
      matching: find.textContaining("Can't be added in Yivi."),
    ),
    findsOneWidget,
  );
  await tapShare(tester);

  // Wait for the SessionScreen to unmount before ending the test (the
  // dismiss flow is async; see cred_missing.dart for the full explanation).
  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  await verifyEmptyActivityLog(tester);
}
