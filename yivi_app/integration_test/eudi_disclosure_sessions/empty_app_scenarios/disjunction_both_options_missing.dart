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

/// OR disjunction (`credential_sets.options: [[email], [phone]]`); wallet
/// empty. Neither option is owned and neither can be added from Yivi. The
/// add screen shows one step with both options as radio rows, neither
/// selectable; the user can only Close.
Future<void> disjunctionBothOptionsMissingTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

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
    "credential_sets": [
      {
        "options": [
          ["mail"],
          ["phone"],
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  expect(find.byType(DisclosureShareScreen), findsNothing);
  expect(find.byType(AddMissingDataScreen), findsOneWidget);

  // One step, two options; neither can be added (no IssueURL).
  expect(findAddStep(0), findsOneWidget);
  expect(findAddStep(1), findsNothing);
  expect(find.text("Which one do you want to add?"), findsOneWidget);
  expect(findAddOption(0, 0), findsOneWidget);
  expect(findAddOption(0, 1), findsOneWidget);
  expect(find.text("Can't be added from Yivi"), findsNWidgets(2));

  // No add button; "Close", and why.
  expect(addButtonTexts(tester), ["Close"]);
  expect(find.byKey(const Key("add_reason")), findsOneWidget);

  await tester.tapAndSettle(
    find.descendant(
      of: find.byKey(const Key("add_button")),
      matching: find.text("Close"),
    ),
  );

  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  await verifyEmptyActivityLog(tester);
}
