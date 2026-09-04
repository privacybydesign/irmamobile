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

/// Test 18: the verifier requires `age_over_65` to be true; the wallet holds
/// an age-verification mdoc that says no. A credential whose value is not
/// among the requested ones is not a candidate at all, so the wallet shows the
/// missing-credential card with the required value ("Age Over 65: Yes"), no
/// obtain button, and no way to share. irmago prerequisite: the unobtainable
/// mdoc descriptor carries the display name and requested value
/// (docs/mdoc-integration-plan.md, irmago prerequisite 2).
Future<void> ageRequestedValueNoMatchTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueAvMdoc(tester, irmaBinding); // age_over_65 is false

  const dcql = """
{
  "credentials": [
    {
      "id": "age",
      "format": "mso_mdoc",
      "meta": { "doctype_value": "eu.europa.ec.av.1" },
      "claims": [
        { "path": ["eu.europa.ec.av.1", "age_over_65"], "values": [true] }
      ]
    }
  ]
}
""";

  final session = await startMdocDisclosure(tester, irmaBinding, dcql);

  expect(find.byType(DisclosureChoicesOverview), findsNothing);
  expect(find.byType(IssueDuringDisclosureScreen), findsOneWidget);

  final cardFinder = find.byType(YiviCredentialCard);
  expect(cardFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardFinder,
    attributes: [(avLabel(65), booleanYes)],
    attributesCompareTo: [(avLabel(65), booleanYes)],
  );

  expect(find.text("Obtain data"), findsNothing);
  expect(find.text("Close"), findsOneWidget);
  await tester.tapAndSettle(find.text("Close"));

  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  // Only the issuance is logged.
  await verifyActivityLogCount(tester, 1);
  expect(await readEudiVerifierResponse(session.transactionId), isNull);
}
