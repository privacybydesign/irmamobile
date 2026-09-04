import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_permission_close_dialog.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_permission_confirm_dialog.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";

import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 29: the user declines at the share dialog and closes the session. No
/// disclosure is logged (only the issuance entry remains) and the verifier
/// holds no response.
Future<void> declineDisclosureTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueAvMdoc(tester, irmaBinding);

  const dcql = """
{
  "credentials": [
    {
      "id": "age",
      "format": "mso_mdoc",
      "meta": { "doctype_value": "eu.europa.ec.av.1" },
      "claims": [
        { "path": ["eu.europa.ec.av.1", "age_over_18"] }
      ]
    }
  ]
}
""";

  final session = await startMdocDisclosure(tester, irmaBinding, dcql);

  await tester.tapAndSettle(find.text("Share data"));
  final confirmDialogFinder = find.byType(DisclosurePermissionConfirmDialog);
  expect(confirmDialogFinder, findsOneWidget);

  await tester.tapAndSettle(find.text("Don't share"));
  expect(confirmDialogFinder, findsNothing);

  await tester.tapAndSettle(find.byType(IrmaCloseButton));
  final closeDialogFinder = find.byType(DisclosurePermissionCloseDialog);
  expect(closeDialogFinder, findsOneWidget);
  await tester.tapAndSettle(find.text("Yes"));
  expect(closeDialogFinder, findsNothing);

  expect(find.byType(HomeScreen), findsOneWidget);

  await verifyActivityLogCount(tester, 1);
  expect(
    await awaitVerifierResponse(session, timeout: const Duration(seconds: 3)),
    isNull,
    reason: "a declined session must leave nothing at the verifier",
  );
}
