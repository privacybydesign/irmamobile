import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_permission_close_dialog.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_permission_confirm_dialog.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";

/// Standard happy-path setup, then user declines at the share-confirm
/// dialog and closes out of the session via the close-confirmation dialog.
/// Verifies the user lands back at home with the session dismissed.
Future<void> declineDisclosureTest(
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

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);

  // Tap the share button to open the confirm dialog.
  await tester.tapAndSettle(find.text("Share data"));

  final disclosureConfirmDialogFinder = find.byType(
    DisclosurePermissionConfirmDialog,
  );
  expect(disclosureConfirmDialogFinder, findsOneWidget);

  // Don't share.
  await tester.tapAndSettle(find.text("Don't share"));
  expect(disclosureConfirmDialogFinder, findsNothing);

  // Close the session.
  await tester.tapAndSettle(find.byType(IrmaCloseButton));

  final disclosureCloseDialogFinder = find.byType(
    DisclosurePermissionCloseDialog,
  );
  expect(disclosureCloseDialogFinder, findsOneWidget);

  await tester.tapAndSettle(find.text("Yes"));
  expect(disclosureCloseDialogFinder, findsNothing);

  // Back at home.
  expect(find.byType(HomeScreen), findsOneWidget);

  // No disclosure log was written; only the prior issuance entry remains.
  await verifyActivityLogCount(tester, 1);
}
