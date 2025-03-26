import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/add_data/add_data_details_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/requestor_header.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> noChoiceTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
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
  await evaluateIntroduction(tester);

  // First, the missing required disjunctions should be obtained using an issue wizard.
  expect(find.text('Collect data'), findsOneWidget);
  expect(tester.widgetList(find.byType(IrmaCredentialCard)).length, 1);

  // Continue and expect the AddDataDetailsScreen
  await tester.tapAndSettle(find.text('Obtain data'));
  expect(find.byType(AddDataDetailsScreen), findsOneWidget);
  await issueMunicipalityPersonalData(tester, irmaBinding);

  // Issue wizard should be completed
  expect(find.text('All required data has been added'), findsOneWidget);
  await tester.tapAndSettle(find.text('Next step'));

  // Expect the choices screen. It should not show change choice options.
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
  expect(find.text('Change choice'), findsNothing);

  final requestorHeaderFinder = find.byType(RequestorHeader);
  await evaluateRequestorHeader(
    tester,
    requestorHeaderFinder,
    localizedRequestorName: 'demo.privacybydesign.foundation',
    isVerified: false,
  );

  await tester.tapAndSettle(find.text('Share data'));

  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}
