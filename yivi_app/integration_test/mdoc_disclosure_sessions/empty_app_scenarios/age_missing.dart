import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";

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
/// the share screen shows one empty spot that "Can't be added in Yivi" and,
/// because the descriptor has no issue URL, a "Close" button with where to
/// get it instead of Share. Nothing can be shared and
/// nothing reaches the verifier.
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

  // URL-less descriptor: no way to add it, only to close.
  await expectCannotAddAndClose(tester);

  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  await verifyEmptyActivityLog(tester);
  expect(await readEudiVerifierResponse(session.transactionId), isNull);
}
