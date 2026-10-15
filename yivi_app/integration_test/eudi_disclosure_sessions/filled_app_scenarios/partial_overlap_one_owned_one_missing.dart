import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/add_missing_data_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";

/// Wallet has email; verifier asks for email AND phone. Backend hides the
/// `DisclosureShareScreen` whenever any issuance step exists, so the
/// wallet renders `AddMissingDataScreen` with the missing phone
/// descriptor — the owned email is **not visible at this stage**.
///
/// On the IRMA-issued spine, the user could add the missing phone from the
/// app. For OID4VCI the same descriptor has no `IssueURL`, so the one button
/// is "Close" (with why above it). The session can only be dismissed.
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

  expect(find.byType(AddMissingDataScreen), findsOneWidget);

  // One step: the missing phone, with its name from VCT metadata. The
  // bridge payload returns `issuer.name == null` — see cred_missing.dart.
  expect(findAddStep(0), findsOneWidget);
  expect(findAddStep(1), findsNothing);
  expect(
    find.descendant(
      of: findAddOption(0, 0),
      matching: find.text("Phone Credential (SD-JWT)"),
    ),
    findsWidgets,
  );
  expect(
    find.descendant(
      of: findAddOption(0, 0),
      matching: find.text("Can't be added from Yivi"),
    ),
    findsWidgets,
  );

  // The owned email is intentionally not visible — backend hides the
  // choices overview while issuance steps exist.
  expect(find.text("test@example.com"), findsNothing);

  // No add button: "Close", because the missing cred has no IssueURL.
  expect(addButtonTexts(tester), ["Close"]);
  expect(find.byKey(const Key("add_reason")), findsOneWidget);

  await tester.tapAndSettle(
    find.descendant(
      of: find.byKey(const Key("add_button")),
      matching: find.text("Close"),
    ),
  );

  // Wait for the SessionScreen to unmount before ending the test.
  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  // No disclosure log was written; only the prior issuance entry remains.
  await verifyActivityLogCount(tester, 1);
}
