import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_make_choice_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_share_dialog.dart';
import 'package:irmamobile/src/screens/session/session_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/disclosure_feedback_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';

Future<void> _fillApp(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await issueEmailAddress(tester, irmaBinding);
  await issueMunicipalityPersonalData(tester, irmaBinding);
  await issueMunicipalityAddress(tester, irmaBinding);
}

Future<void> filledChoiceMixedTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Fill app with:
  // Email and personal data from municipality
  await _fillApp(tester, irmaBinding);

  // Session requesting:
  // Address from municipality OR
  // Address from iDIN, with city
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.address.street", "irma-demo.gemeente.address.houseNumber", "irma-demo.gemeente.address.city" ],
              [ "irma-demo.idin.idin.address", "irma-demo.idin.idin.city" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // Dismiss introduction screen.
  await tester.waitFor(find.text('Share your data in 3 simple steps:'));
  await tester.tapAndSettle(find.descendant(
    of: find.byType(IrmaButton),
    matching: find.text('Get going'),
  ));

  // Should go straight to overview screen,
  // because the address has already been obtained
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
  await tester.waitFor(find.text('This is the data you are going to share:'));

  // Expect the already obtained municipality address
  final cardsFinder = find.byType(IrmaCredentialCard);
  expect(cardsFinder, findsOneWidget);
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

  // Change choice should be visible
  final changeChoiceFinder = find.text('Change choice');
  expect(changeChoiceFinder, findsOneWidget);

  // Press the change choice
  await tester.tapAndSettle(changeChoiceFinder);

  // Expect make choice screen
  expect(find.byType(DisclosurePermissionMakeChoiceScreen), findsOneWidget);

  //This screen to have two options
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
    style: IrmaCardStyle.highlighted,
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: 'Demo iDIN',
    issuerName: 'Demo iDIN',
    attributes: {},
    style: IrmaCardStyle.outlined,
  );

  // Press iDin option
  await tester.tapAndSettle(cardsFinder.at(1));

  // The styling of the cards should represent this choice
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    style: IrmaCardStyle.outlined,
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    style: IrmaCardStyle.highlighted,
  );

  // Issue iDin
  await issueIdin(tester, irmaBinding);

  // Now two filled cards should be present
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

  // Expect choices overview
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
  expect(find.text('This is the data you are going to share:'), findsOneWidget);

  // Now two filled cards should be visible
  expect(cardsFinder, findsOneWidget);
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
