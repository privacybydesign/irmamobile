import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/add_data/schemaless_add_data_details_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/widgets/requestor_header.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> noChoiceTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Full name AND nationality
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.personalData.fullname", "irma-demo.gemeente.personalData.nationality" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // First, the missing required disjunctions should be obtained using an issue wizard.
  expect(find.text("Collect data"), findsOneWidget);
  expect(tester.widgetList(findCredentialCards()).length, 1);

  // Continue and expect the SchemalessAddDataDetailsScreen
  await tester.tapAndSettle(find.text("Obtain data"));
  expect(find.byType(SchemalessAddDataDetailsScreen), findsOneWidget);
  await issueMunicipalityPersonalData(tester, irmaBinding);

  // Issue wizard should be completed
  expect(find.text("All required data has been added."), findsOneWidget);
  await tester.tapAndSettle(find.text("Next step"));

  // Expect the choices screen. It should not show change choice options.
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  expect(find.text("Change choice"), findsNothing);

  final requestorHeaderFinder = find.byType(RequestorHeader);
  await evaluateRequestorHeader(
    tester,
    requestorHeaderFinder,
    localizedRequestorName: "is.demo.staging.yivi.app",
    isVerified: false,
  );

  await tapShare(tester);
  await evaluateFeedback(tester);
}
