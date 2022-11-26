import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_make_choice_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_share_dialog.dart';
import 'package:irmamobile/src/screens/session/session_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/disclosure_feedback_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../helpers/helpers.dart';
import '../../irma_binding.dart';
import '../../helpers/issuance_helpers.dart';
import '../../util.dart';

Future<void> filledDisconTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueDemoCredentials(tester, irmaBinding);

  // Session requesting:
  // Address from municipality OR iDIN
  // AND mobile number
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.address.street", "irma-demo.gemeente.address.houseNumber", "irma-demo.gemeente.address.city" ],
              [ "irma-demo.idin.idin.address", "irma-demo.idin.idin.city" ]
            ],
            [
              [ "irma-demo.sidn-pbdf.email.email" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present
  await irmaBinding.repository.startTestSession(sessionRequest);

  // Dismiss introduction screen.
  await tester.waitFor(find.text('Share your data'));
  await tester.tapAndSettle(find.descendant(
    of: find.byType(IrmaButton),
    matching: find.text('Get going'),
  ));

  // Both cards are already obtained
  // Expect choices screen.
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

  // Expect cards to have the right content
  final cardsFinder = find.byType(IrmaCredentialCard);

  expect(cardsFinder, findsNWidgets(2));
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Address',
    issuerName: 'Demo Municipality',
    attributes: {
      'Street': 'Meander',
      'House number': '501',
      'City': 'Arnhem',
    },
    style: IrmaCardStyle.normal,
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Email address': 'test@example.com',
    },
    style: IrmaCardStyle.normal,
  );

  // Tap the first change choice
  final changeChoiceFinder = find.text('Change choice');
  await tester.scrollUntilVisible(changeChoiceFinder.first, 50);
  await tester.tapAndSettle(changeChoiceFinder.first);

  // Expect two options to be present
  // First one should be the already obtained Demo Address
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Address',
    issuerName: 'Demo Municipality',
    attributes: {
      'Street': 'Meander',
      'House number': '501',
      'City': 'Arnhem',
    },
    style: IrmaCardStyle.highlighted,
  );

  // Second card should show the option to add iDIN
  final secondCardFinder = cardsFinder.at(1);
  await evaluateCredentialCard(
    tester,
    secondCardFinder,
    credentialName: 'Demo iDIN',
    issuerName: 'Demo iDIN',
    attributes: {},
    style: IrmaCardStyle.outlined,
  );
  await tester.scrollUntilVisible(
    secondCardFinder,
    50,
  );
  // Tap iDIN option
  await tester.tapAndSettle(secondCardFinder);

  // Evaluate the card styling again now that iDIN is selected
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Address',
    issuerName: 'Demo Municipality',
    style: IrmaCardStyle.outlined,
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: 'Demo iDIN',
    issuerName: 'Demo iDIN',
    style: IrmaCardStyle.highlighted,
  );

  await issueIdin(tester, irmaBinding);

  // Now the second card should be filled too
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Address',
    issuerName: 'Demo Municipality',
    attributes: {
      'Street': 'Meander',
      'House number': '501',
      'City': 'Arnhem',
    },
    style: IrmaCardStyle.outlined,
  );

  // Second card should show the option to add iDIN
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: 'Demo iDIN',
    issuerName: 'Demo iDIN',
    attributes: {
      'Address': 'Meander 501',
      'City': 'Arnhem',
    },
    style: IrmaCardStyle.highlighted,
  );

  await tester.tapAndSettle(find.text('Done'));
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

  // Check the second change choice
  await tester.scrollUntilVisible(
    cardsFinder.at(1),
    50,
  );
  await tester.tapAndSettle(changeChoiceFinder.at(1));

  // Evaluate the choice screen
  expect(find.byType(DisclosurePermissionMakeChoiceScreen), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Email address': 'test@example.com',
    },
    style: IrmaCardStyle.highlighted,
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {},
    style: IrmaCardStyle.outlined,
  );

  // Leave the choices as they are
  await tester.tapAndSettle(find.text('Done'));
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
  expect(find.text('This is the data you are going to share:'), findsOneWidget);

  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo iDIN',
    issuerName: 'Demo iDIN',
    attributes: {
      'Address': 'Meander 501',
      'City': 'Arnhem',
    },
    style: IrmaCardStyle.normal,
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Email address': 'test@example.com',
    },
    style: IrmaCardStyle.normal,
  );

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
