import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/issue_during_disclosure_screen.dart";

import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 13: the verifier asks only for an optional age-verification mdoc and
/// the wallet is empty. Nothing is required, so the user can submit an empty
/// disclosure; the activity log still records who the session was with,
/// mirroring the SD-JWT and IRMA `completely_optional` scenarios.
Future<void> completelyOptionalCanSubmitEmptyTest(
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
  ],
  "credential_sets": [
    { "required": false, "options": [["age"]] }
  ]
}
""";

  await startMdocDisclosure(tester, irmaBinding, dcql);

  // No required credential is missing, so the wallet stays on the choices
  // overview rather than entering the issuance wizard.
  expect(find.byType(IssueDuringDisclosureScreen), findsNothing);
  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  expect(find.text("No data selected"), findsOneWidget);

  await shareAndFinishEudiDisclosure(tester);

  await verifyEmptyDisclosureActivityLog(
    tester,
    expectedRequestorName: eudiVerifierDisplayName,
  );
}
