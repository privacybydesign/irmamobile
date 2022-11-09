import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_discon_stepper.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choice.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_obtain_credentials_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_template_stepper.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
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
  await tester.pumpAndSettle();
  expect(find.text('Share your data in 3 simple steps:'), findsOneWidget);
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
    matching: find.byType(IrmaCredentialCard),
  );
  expect(templateCardsFinder, findsNWidgets(2));

  // The first card should be highlighted
  expect((templateCardsFinder.evaluate().first.widget as IrmaCredentialCard).style, IrmaCardStyle.highlighted);
  expect((templateCardsFinder.evaluate().elementAt(1).widget as IrmaCredentialCard).style, IrmaCardStyle.normal);

  // Issue the personal data
  await issueMunicipalityPersonalData(tester, irmaBinding);

  // The second card should now be highlighted
  expect((templateCardsFinder.evaluate().first.widget as IrmaCredentialCard).style, IrmaCardStyle.normal);
  expect((templateCardsFinder.evaluate().elementAt(1).widget as IrmaCredentialCard).style, IrmaCardStyle.highlighted);

  // Issue the email
  await issueEmailAddress(tester, irmaBinding);

  // Both should be finished now
  expect((templateCardsFinder.evaluate().first.widget as IrmaCredentialCard).style, IrmaCardStyle.normal);
  expect((templateCardsFinder.evaluate().elementAt(1).widget as IrmaCredentialCard).style, IrmaCardStyle.normal);

  // Button should say done now
  await tester.tap(find.text('Done'));
  await tester.pump();

  // Issue wizard should be completed
  final bottomBarButtonFinder = find.byKey(const Key('bottom_bar_primary'));
  await tester.tap(bottomBarButtonFinder);
  await tester.pump();

  //Share data
  await tester.tap(bottomBarButtonFinder);
  await tester.pump(const Duration(seconds: 1));

  // Confirm the dialog
  await tester.tap(find.byKey(const Key('confirm_share_button')));
  await tester.pump(const Duration(seconds: 1));

  // Success screen
  await tester.tap(bottomBarButtonFinder);
  await tester.pump();
}
