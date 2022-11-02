import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_discon_stepper.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choice.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_obtain_credentials_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_share_dialog.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_template_stepper.dart';
import 'package:irmamobile/src/screens/session/session_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/disclosure_feedback_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../helpers/helpers.dart';
import '../../irma_binding.dart';
import '../../helpers/issuance_helpers.dart';
import '../../util.dart';

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

  // Dismiss introduction screen.
  await tester.waitFor(find.text('Share your data in 3 simple steps:'));
  await tester.tapAndSettle(find.descendant(of: find.byType(IrmaButton), matching: find.text('Get going')));

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
  await tester.pumpAndSettle(const Duration(seconds: 1));
  await tester.tapAndSettle(personalDataFinder);
  await tester.pumpAndSettle(const Duration(seconds: 1));
  await tester.tapAndSettle(find.text('Obtain data'));
  await tester.pumpAndSettle(const Duration(seconds: 1));

  // Expect sub-issue wizard
  expect(find.byType(DisclosurePermissionObtainCredentialsScreen), findsOneWidget);

  // Expect a template stepper
  final templateStepperFinder = find.byType(DisclosureTemplateStepper);
  expect(templateStepperFinder, findsOneWidget);

  // The template stepper should have two items
  final templateCardsFinder = find.descendant(
    of: templateStepperFinder,
    matching: find.byType(IrmaCredentialCard),
  );
  expect(templateCardsFinder, findsNWidgets(2));

  // The first card should be highlighted
  await evaluateCredentialCard(
    tester,
    templateCardsFinder.first,
    credentialName: 'Demo Personal data',
    issuerName: 'Demo Municipality',
    attributes: {},
    style: IrmaCardStyle.highlighted,
  );
  await evaluateCredentialCard(
    tester,
    templateCardsFinder.at(1),
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {},
    style: IrmaCardStyle.normal,
  );

  // Issue the personal data
  await issueMunicipalityPersonalData(tester, irmaBinding);

  // The second card should now be highlighted
  await evaluateCredentialCard(
    tester,
    templateCardsFinder.first,
    credentialName: 'Demo Personal data',
    issuerName: 'Demo Municipality',
    attributes: {},
    style: IrmaCardStyle.normal,
  );
  await evaluateCredentialCard(
    tester,
    templateCardsFinder.at(1),
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {},
    style: IrmaCardStyle.highlighted,
  );

  // Issue the email
  await issueEmailAddress(tester, irmaBinding);

  // Both should be finished now
  await evaluateCredentialCard(
    tester,
    templateCardsFinder.first,
    credentialName: 'Demo Personal data',
    issuerName: 'Demo Municipality',
    attributes: {},
    style: IrmaCardStyle.normal,
  );
  await evaluateCredentialCard(
    tester,
    templateCardsFinder.at(1),
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {},
    style: IrmaCardStyle.normal,
  );

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

  // Confirm the dialog
  expect(find.byType(DisclosurePermissionConfirmDialog), findsOneWidget);
  await tester.tapAndSettle(find.text('Share'));

  // Expect the success screen
  final feedbackScreenFinder = find.byType(DisclosureFeedbackScreen);
  expect(feedbackScreenFinder, findsOneWidget);
  expect(
    (feedbackScreenFinder.evaluate().single.widget as DisclosureFeedbackScreen).feedbackType,
    DisclosureFeedbackType.success,
  );
  await tester.tapAndSettle(find.text('OK'));

  // Session flow should be over now
  expect(find.byType(SessionScreen), findsNothing);
}
