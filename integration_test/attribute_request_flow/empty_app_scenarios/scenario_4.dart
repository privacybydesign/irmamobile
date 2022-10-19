import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_discon_stepper.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choice.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_share_dialog.dart';
import 'package:irmamobile/src/screens/session/session_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/disclosure_feedback_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';

Future<void> scenario4(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.address.street", "irma-demo.gemeente.address.houseNumber", "irma-demo.gemeente.address.city" ],
              [ "irma-demo.idin.idin.address", "irma-demo.idin.idin.city"]
            ],
            [
              [ "irma-demo.nuts.agb.agbcode"]
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

  // The choice should consist of two cards
  final choiceCardsFinder = find.descendant(
    of: choiceFinder,
    matching: find.byType(IrmaCredentialCard),
  );
  expect(choiceCardsFinder, findsNWidgets(2));

  // First card in the choice should be highlighted, second card should be outlined
  expect((choiceCardsFinder.evaluate().first.widget as IrmaCredentialCard).style, IrmaCardStyle.highlighted);
  expect((choiceCardsFinder.evaluate().elementAt(1).widget as IrmaCredentialCard).style, IrmaCardStyle.outlined);

  // Select the iDIN option
  await tester.tapAndSettle(find.text('Demo iDIN').first);

  // Now the second card in the choice should be highlighted, second card should be outlined
  expect((choiceCardsFinder.evaluate().first.widget as IrmaCredentialCard).style, IrmaCardStyle.outlined);
  expect((choiceCardsFinder.evaluate().elementAt(1).widget as IrmaCredentialCard).style, IrmaCardStyle.highlighted);

  // Obtain the data from iDIN
  await issueCredentials(tester, irmaBinding, {
    'irma-demo.idin.idin.initials': 'W.L.',
    'irma-demo.idin.idin.familyname': 'Bruijn',
    'irma-demo.idin.idin.dateofbirth': '10-04-1965',
    'irma-demo.idin.idin.gender': 'V',
    'irma-demo.idin.idin.address': 'Teststraat 12',
    'irma-demo.idin.idin.zipcode': '1234 AB',
    'irma-demo.idin.idin.city': 'Roermond',
    'irma-demo.idin.idin.country': 'Netherlands',
  });

  // The choice should have disappeared
  expect(choiceFinder, findsNothing);

  // Now the discon stepper should consist of two cards
  final disConCardsFinder = find.descendant(
    of: disConStepperFinder,
    matching: find.byType(IrmaCredentialCard),
  );
  expect(disConCardsFinder, findsNWidgets(2));

  // Now only the second discon card should be highlighted
  expect((disConCardsFinder.evaluate().first.widget as IrmaCredentialCard).style, IrmaCardStyle.normal);
  expect((disConCardsFinder.evaluate().elementAt(1).widget as IrmaCredentialCard).style, IrmaCardStyle.highlighted);

  // Obtain the data from Nuts
  await issueCredentials(tester, irmaBinding, {
    'irma-demo.nuts.agb.agbcode': '7722255556',
  });

  // Issue wizard should be completed
  expect(find.text('All required data has been added.'), findsOneWidget);
  await tester.tapAndSettle(find.text('Next step'));

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
