import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/add_missing_data_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";

/// AND request for two creds (email + phone); wallet empty. Both missing
/// descriptors appear as steps of `AddMissingDataScreen`: the first is
/// current, the second waits. Neither can be added, so the button is
/// "Close".
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

  expect(find.byType(DisclosureShareScreen), findsNothing);
  expect(find.byType(AddMissingDataScreen), findsOneWidget);

  // One step per missing credential: the first is current (its option
  // row), the second is a later step.
  expect(findAddStep(0), findsOneWidget);
  expect(findAddStep(1), findsOneWidget);
  expect(findAddOption(0, 0), findsOneWidget);
  expect(findAddOption(1, 0), findsNothing);
  expect(
    find.descendant(
      of: findAddOption(0, 0),
      matching: find.text("Can't be added from Yivi"),
    ),
    findsWidgets,
  );

  // No add button — neither cred can be added; "Close", and why.
  expect(addButtonTexts(tester), ["Close"]);
  expect(find.byKey(const Key("add_reason")), findsOneWidget);

  await tester.tapAndSettle(
    find.descendant(
      of: find.byKey(const Key("add_button")),
      matching: find.text("Close"),
    ),
  );

  // Wait for the SessionScreen to unmount before ending the test (the
  // dismiss flow is async; see cred_missing.dart for the full explanation).
  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  await verifyEmptyActivityLog(tester);
}
