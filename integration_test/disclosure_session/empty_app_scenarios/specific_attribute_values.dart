import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_discon_stepper.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_share_dialog.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_wrong_credentials_obtained_dialog.dart';
import 'package:irmamobile/src/screens/session/session_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/disclosure_feedback_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card_attribute_list.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../helpers/helpers.dart';
import '../../irma_binding.dart';
import '../../helpers/issuance_helpers.dart';
import '../../util.dart';

Future<void> specificAttributeValuesTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  const defaultTextColor = Color(0xff454545);
  const successColor = Color(0xff33ad38);
  const errorColor = Color(0xffbd1919);

  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Bank account number from iDeal. BIC has to be RABONL2U. AND
  // Initials, family name and city from iDIN. The city has to be Arnhem
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.idin.idin.initials", "irma-demo.idin.idin.familyname", { "type" : "irma-demo.idin.idin.city", "value" : "Arnhem" }]
            ],
            [
              [ "irma-demo.ideal.ideal.iban", { "type": "irma-demo.ideal.ideal.bic", "value": "RABONL2U" }]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // Dismiss introduction screen.
  await tester.waitFor(find.text('Share your data'));
  await tester.tapAndSettle(find.descendant(of: find.byType(IrmaButton), matching: find.text('Get going')));

  // Expect a disclose stepper
  final disConStepperFinder = find.byType(DisclosureDisconStepper);
  expect(disConStepperFinder, findsOneWidget);

  // The discon stepper should two cards
  final choiceCardsFinder = find.descendant(
    of: disConStepperFinder,
    matching: find.byType(IrmaCredentialCard),
  );
  expect(choiceCardsFinder, findsNWidgets(2));

  // First card should be highlighted.
  final firstCardFinder = choiceCardsFinder.first;
  expect((firstCardFinder.evaluate().first.widget as IrmaCredentialCard).style, IrmaCardStyle.highlighted);

  // First card should show an attribute list
  final firstCardAttListFinder = find.descendant(
    of: firstCardFinder,
    matching: find.byType(IrmaCredentialCardAttributeList),
  );
  expect(firstCardAttListFinder, findsOneWidget);

  // The name of the attribute with a value should be visible and styled normally
  final firstCardAttNameFinder = find.descendant(
    of: firstCardAttListFinder,
    matching: find.text('City'),
  );
  expect(firstCardAttNameFinder, findsOneWidget);
  expect((firstCardAttNameFinder.evaluate().first.widget as Text).style?.color!, defaultTextColor);

  // The names of the other requested attributes (without a value) should not be visible
  expect(
    find.descendant(
      of: firstCardAttListFinder,
      matching: find.text('Initials'),
    ),
    findsNothing,
  );
  expect(
    find.descendant(
      of: firstCardAttListFinder,
      matching: find.text('Family name'),
    ),
    findsNothing,
  );

  // The value of the attribute should be visible and styled green
  final firstCardAttValueFinder = find.descendant(
    of: firstCardAttListFinder,
    matching: find.text('Arnhem'),
  );
  expect(firstCardAttValueFinder, findsOneWidget);
  expect((firstCardAttValueFinder.evaluate().first.widget as Text).style?.color!, successColor);

  // Find the second card and make sure its is not highlighted yet
  final secondCardFinder = choiceCardsFinder.at(1);
  await tester.scrollUntilVisible(
    secondCardFinder,
    150,
    maxScrolls: 300,
  );

  await evaluateCredentialCard(tester, secondCardFinder, style: IrmaCardStyle.normal);

  // Issue the right iDIN credential
  await issueIdin(tester, irmaBinding);

  // Tap it and the styling should change.
  await tester.tapAndSettle(secondCardFinder);
  await evaluateCredentialCard(tester, secondCardFinder, style: IrmaCardStyle.highlighted);

  // Second card should also show an attribute list
  final secondCardAttListFinder = find.descendant(
    of: secondCardFinder,
    matching: find.byType(IrmaCredentialCardAttributeList),
  );
  expect(secondCardAttListFinder, findsOneWidget);

  // The name of the attribute should be visible and styled normally
  final secondCardAttNameFinder = find.descendant(
    of: secondCardAttListFinder,
    matching: find.text('BIC'),
  );
  expect(secondCardAttNameFinder, findsOneWidget);
  expect((secondCardAttNameFinder.evaluate().first.widget as Text).style?.color!, defaultTextColor);

  // The value of the attribute should be visible and styled green
  final secondCardAttValueFinder = find.descendant(
    of: secondCardAttListFinder,
    matching: find.text('RABONL2U'),
  );
  expect(secondCardAttValueFinder, findsOneWidget);
  expect((secondCardAttValueFinder.evaluate().first.widget as Text).style?.color!, successColor);

  // Now obtain the iDEAL credential with the wrong BIC
  await issueCredentials(tester, irmaBinding, {
    'irma-demo.ideal.ideal.fullname': 'John Doe',
    'irma-demo.ideal.ideal.iban': 'NL60RABO5614740864',
    'irma-demo.ideal.ideal.bic': 'INGBNL2A',
  });

  // Wrong credentials added dialog should appear
  final wrongCredAddedDialogFinder = find.byType(DisclosurePermissionWrongCredentialsAddedDialog);
  expect(wrongCredAddedDialogFinder, findsOneWidget);

  // Dialog should show two credential cards
  final dialogCardsFinder = find.descendant(
    of: wrongCredAddedDialogFinder,
    matching: find.byType(IrmaCredentialCard),
  );
  expect(dialogCardsFinder, findsNWidgets(2));

  // First card should show the added credential not matching this session
  final firstDialogCardFinder = dialogCardsFinder.first;
  expect(firstDialogCardFinder, findsOneWidget);

  // First card in dialog should have an attribute list
  final firstDialogCardAttListFinder = find.descendant(
    of: firstDialogCardFinder,
    matching: find.byType(IrmaCredentialCardAttributeList),
  );
  expect(firstDialogCardAttListFinder, findsOneWidget);

  // The name of the attribute should be visible and styled normally
  final firstDialogCardAttNameFinder = find.descendant(
    of: firstDialogCardAttListFinder,
    matching: find.text('BIC'),
  );
  expect(firstDialogCardAttNameFinder, findsOneWidget);
  expect((firstDialogCardAttNameFinder.evaluate().first.widget as Text).style?.color!, defaultTextColor);

  // The attribute value should match the added credential and should be styled red
  final firstDialogCardAttValueFinder = find.descendant(
    of: firstDialogCardAttListFinder,
    matching: find.text('INGBNL2A'),
  );
  expect(firstDialogCardAttValueFinder, findsOneWidget);
  expect((firstDialogCardAttValueFinder.evaluate().first.widget as Text).style?.color!, errorColor);

  // The second card should also be visible
  final secondDialogCardFinder = dialogCardsFinder.at(1);
  expect(secondDialogCardFinder, findsOneWidget);

  // Second card in dialog should also have an attribute list
  final secondDialogCardAttListFinder = find.descendant(
    of: secondDialogCardFinder,
    matching: find.byType(IrmaCredentialCardAttributeList),
  );
  expect(secondDialogCardAttListFinder, findsOneWidget);

  // The name of the attribute should be visible and styled normally
  final secondDialogCardAttNameFinder = find.descendant(
    of: secondDialogCardAttListFinder,
    matching: find.text('BIC'),
  );
  expect(secondDialogCardAttNameFinder, findsOneWidget);
  expect((secondDialogCardAttNameFinder.evaluate().first.widget as Text).style?.color!, defaultTextColor);

  // The attribute value should match requested value
  final secondDialogCardAttValueFinder = find.descendant(
    of: secondDialogCardAttListFinder,
    matching: find.text('RABONL2U'),
  );
  expect(secondDialogCardAttValueFinder, findsOneWidget);
  expect((secondDialogCardAttValueFinder.evaluate().first.widget as Text).style?.color!, successColor);

  // Close the dialog
  final okButtonFinder = find.text('OK');
  await tester.ensureVisible(okButtonFinder);
  await tester.pumpAndSettle();
  await tester.tapAndSettle(okButtonFinder);

  // Now issue the credential with requested BIC
  await issueCredentials(tester, irmaBinding, {
    'irma-demo.ideal.ideal.fullname': 'John Doe',
    'irma-demo.ideal.ideal.iban': 'NL82RABO9763136946',
    'irma-demo.ideal.ideal.bic': 'RABONL2U',
  });

  // No dialog should appear
  expect(wrongCredAddedDialogFinder, findsNothing);

  // The disclosure cards should not have a attribute cards list.
  expect(
    find.descendant(
      of: dialogCardsFinder,
      matching: find.byType(IrmaCredentialCardAttributeList),
    ),
    findsNothing,
  );

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
