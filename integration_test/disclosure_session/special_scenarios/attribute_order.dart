import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> attributeOrderTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
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
  await evaluateIntroduction(tester);

  // Expect the choices screen
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

  // Check the attribute order.
  await evaluateCredentialCard(
    tester,
    find.byType(IrmaCredentialCard),
    credentialName: 'Demo Address',
    issuerName: 'Demo Municipality',
    attributes: {
      'Street': 'Meander',
      'House number': '501',
      'City': 'Arnhem',
      'Municipality': 'Arnhem',
    },
    style: IrmaCardStyle.normal,
  );

  await tester.tapAndSettle(find.text('Share data'));
  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}
