import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../disclosure_helpers.dart";

Future<void> attributeOrderTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueDemoCredentials(tester, irmaBinding);

  // Session requesting:
  // Address from municipality
  // We use a different order to test whether the app correctly re-orders them.
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [
                "irma-demo.gemeente.address.municipality",
                "irma-demo.gemeente.address.city",
                "irma-demo.gemeente.address.houseNumber",
                "irma-demo.gemeente.address.street"
              ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);
  await waitForRequest(tester);

  // Expect the choices screen
  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  // Check the attribute order.
  await evaluateCredentialCard(
    tester,
    findCredentialCards(),
    credentialName: "Demo Address",
    issuerName: "Demo Municipality",
    attributes: [
      ("Street", "Meander"),
      ("House number", "501"),
      ("City", "Arnhem"),
      ("Municipality", "Arnhem"),
    ],
    style: IrmaCardStyle.normal,
  );

  await tapShare(tester);
  await evaluateFeedback(tester);
}
