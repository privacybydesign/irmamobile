import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/error/error_screen.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";

import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";

/// Test 30: the one representative refusal. The verifier asks the age
/// document for an element its relying-party certificate does not authorise
/// (`eye_colour`). irmago refuses the request before any permission screen;
/// the wallet shows its error screen, nothing is logged and nothing reaches
/// the verifier.
Future<void> unauthorizedElementErrorTest(
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
        { "path": ["eu.europa.ec.av.1", "age_over_18"] },
        { "path": ["eu.europa.ec.av.1", "eye_colour"] }
      ]
    }
  ]
}
""";

  final session = await startEudiVerifierSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(session.uri);

  await tester.pumpUntilFound(
    find.byType(ErrorScreen),
    timeout: const Duration(seconds: 30),
  );
  expect(find.byType(DisclosureChoicesOverview), findsNothing);

  await tester.tapAndSettle(find.text("OK"));
  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  // Only the issuance is logged.
  await verifyActivityLogCount(tester, 1);
  expect(await readEudiVerifierResponse(session.transactionId), isNull);
}
