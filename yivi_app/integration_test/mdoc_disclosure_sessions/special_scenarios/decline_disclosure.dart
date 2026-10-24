import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/widgets/glass/glass_dialog.dart";
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

  await tester.waitFor(find.byKey(const Key("share_button")));

  await tester.tapAndSettle(find.byType(IrmaCloseButton));
  final closeDialogFinder = find.byType(GlassDialog);
  expect(closeDialogFinder, findsOneWidget);
  // Scope to the dialog: the permission screen behind it renders an
  // "Age Over 18 -> Yes" attribute row, so a bare find.text("Yes") is ambiguous.
  await tester.tapAndSettle(
    find.descendant(of: closeDialogFinder, matching: find.text("Yes")),
  );
  expect(closeDialogFinder, findsNothing);

  expect(find.byType(HomeScreen), findsOneWidget);

  await verifyActivityLogCount(tester, 1);
  expect(
    await awaitVerifierResponse(session, timeout: const Duration(seconds: 3)),
    isNull,
    reason: "a declined session must leave nothing at the verifier",
  );
}
