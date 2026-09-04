import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/issue_during_disclosure_screen.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 11: the verifier asks for `age_over_18` from the age-verification
/// mdoc and the wallet holds none.
///
/// irmago answers a query nothing owns with a URL-less descriptor built from
/// the query itself (there is no discovery document for an mdoc docType), so
/// the wallet renders the issue-during-disclosure screen with a single
/// missing-credential card and, because the descriptor has no issue URL, a
/// "Close" button instead of "Obtain data". Nothing can be shared and nothing
/// reaches the verifier.
Future<void> ageMissingTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

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

  // No issuance: the wallet is empty.
  final session = await startMdocDisclosure(tester, irmaBinding, dcql);

  expect(find.byType(DisclosureChoicesOverview), findsNothing);
  expect(find.byType(IssueDuringDisclosureScreen), findsOneWidget);
  expect(find.byType(YiviCredentialCard), findsOneWidget);

  // URL-less descriptor: no way to obtain, only to close.
  expect(find.text("Obtain data"), findsNothing);
  expect(find.text("Close"), findsOneWidget);
  await tester.tapAndSettle(find.text("Close"));

  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  await verifyEmptyActivityLog(tester);
  expect(await readEudiVerifierResponse(session.transactionId), isNull);
}
