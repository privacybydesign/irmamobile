import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/add_missing_data_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

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

  // No required credential is missing, so the wallet goes straight to the
  // share screen rather than "Add data first": nothing is required, the age
  // mdoc is an optional row, and the button shares nothing.
  expect(find.byType(AddMissingDataScreen), findsNothing);
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  expect(find.text("Nothing required"), findsOneWidget);
  expect(
    find.byKey(const Key("share_add_optional_0"), skipOffstage: false),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.byKey(const Key("share_button")),
      matching: find.text("Share without data"),
    ),
    findsOneWidget,
  );

  await shareAndFinishEudiDisclosure(tester);

  await verifyEmptyDisclosureActivityLog(
    tester,
    expectedRequestorName: eudiVerifierDisplayName,
  );
}
