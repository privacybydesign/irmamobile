import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/add_data/add_data_details_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_discon_stepper.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choice.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_obtain_credentials_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_template_stepper.dart';
import 'package:irmamobile/src/widgets/credential_card/yivi_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> choiceMixedSourcesTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Student/employee id from university OR
  // Full name from municipality AND email address
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.pbdf.surfnet-2.id" ],
              [ "irma-demo.gemeente.personalData.fullname", "irma-demo.sidn-pbdf.email.email"]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  // Expect a disclose stepper
  final disConStepperFinder = find.byType(DisclosureDisconStepper);
  expect(disConStepperFinder, findsOneWidget);

  // The discon stepper should have one choice
  final choiceFinder = find.descendant(
    of: disConStepperFinder,
    matching: find.byType(DisclosurePermissionChoice),
  );
  expect(choiceFinder, findsOneWidget);

  // Select the second choice
  final personalDataFinder = find.text('Demo Personal data');
  await tester.ensureVisible(personalDataFinder);
  await tester.pumpAndSettle();
  await tester.tapAndSettle(personalDataFinder);
  await tester.tapAndSettle(find.text('Obtain data'));

  // Expect sub-issue wizard
  expect(find.byType(DisclosurePermissionObtainCredentialsScreen), findsOneWidget);

  // Expect a template stepper
  final templateStepperFinder = find.byType(DisclosureTemplateStepper);
  expect(templateStepperFinder, findsOneWidget);

  // The template stepper should have two items
  final templateCardsFinder = find.descendant(
    of: templateStepperFinder,
    matching: find.byType(YiviCredentialCard),
  );
  expect(templateCardsFinder, findsNWidgets(2));

  // The first card should be highlighted
  expect((templateCardsFinder.evaluate().first.widget as YiviCredentialCard).style, IrmaCardStyle.highlighted);
  expect((templateCardsFinder.evaluate().elementAt(1).widget as YiviCredentialCard).style, IrmaCardStyle.normal);

  // Continue and expect the AddDataDetailsScreen
  await tester.tapAndSettle(find.text('Obtain data'));
  expect(find.byType(AddDataDetailsScreen), findsOneWidget);
  await issueMunicipalityPersonalData(tester, irmaBinding);

  // The second card should now be highlighted
  expect((templateCardsFinder.evaluate().first.widget as YiviCredentialCard).style, IrmaCardStyle.normal);
  expect((templateCardsFinder.evaluate().elementAt(1).widget as YiviCredentialCard).style, IrmaCardStyle.highlighted);

  // Continue and expect the AddDataDetailsScreen
  await tester.tapAndSettle(find.text('Obtain data'));
  expect(find.byType(AddDataDetailsScreen), findsOneWidget);
  await issueEmailAddress(tester, irmaBinding);

  // Both should be finished now
  expect((templateCardsFinder.evaluate().first.widget as YiviCredentialCard).style, IrmaCardStyle.normal);
  expect((templateCardsFinder.evaluate().elementAt(1).widget as YiviCredentialCard).style, IrmaCardStyle.normal);

  // Button should say done now
  await tester.tapAndSettle(find.text('Done'));
  await tester.pumpAndSettle(const Duration(seconds: 1));

  // Issue wizard should be completed
  final nextStepButtonFinder = find.text('Next step');
  await tester.waitFor(nextStepButtonFinder);
  await tester.ensureVisible(nextStepButtonFinder);
  await tester.tapAndSettle(nextStepButtonFinder);

  // Expect the choices screen
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
  await tester.tapAndSettle(find.text('Share data'));

  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}
