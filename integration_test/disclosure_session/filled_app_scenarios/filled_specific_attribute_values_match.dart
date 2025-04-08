import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/add_data/add_data_details_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_issue_wizard_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_wrong_credentials_obtained_dialog.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> filledSpecificAttributeValuesMatchTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueDemoCredentials(tester, irmaBinding);

  // Address from municipality where city hast to be Arnhem AND
  // Email address where domain has to be test.com
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.address.street" , "irma-demo.gemeente.address.houseNumber", { "type" : "irma-demo.gemeente.address.city", "value": "Arnhem" }  ]
            ],
            [
              [ "irma-demo.sidn-pbdf.email.email" , { "type" : "irma-demo.sidn-pbdf.email.domain" , "value" : "test.com"} ]
            ]
          ]
        }
      ''';
  await irmaBinding.repository.startTestSession(sessionRequest);

  await evaluateIntroduction(tester);

  // Expect a stepper with the email card
  expect(find.byType(DisclosurePermissionIssueWizardScreen), findsOneWidget);
  final cardsFinder = find.byType(IrmaCredentialCard);
  expect(cardsFinder, findsOneWidget);

  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation',
    attributes: {
      'Email domain name': 'test.com',
    },
    attributesCompareTo: {
      'Email domain name': 'test.com',
    },
    style: IrmaCardStyle.highlighted,
  );

  await tester.tapAndSettle(find.text('Obtain data'));
  expect(find.byType(AddDataDetailsScreen), findsOneWidget);

  // Now obtain the email credential with wrong domain
  await issueCredentials(tester, irmaBinding, {
    'irma-demo.sidn-pbdf.email.email': 'test@demo.com',
    'irma-demo.sidn-pbdf.email.domain': 'demo.com',
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

  // Evaluate the cards in the dialog
  await evaluateCredentialCard(
    tester,
    dialogCardsFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation',
    attributes: {
      'Email domain name': 'demo.com',
    },
    attributesCompareTo: {
      'Email domain name': 'test.com',
    },
    style: IrmaCardStyle.normal,
  );
  await evaluateCredentialCard(
    tester,
    dialogCardsFinder.at(1),
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation',
    attributes: {
      'Email domain name': 'test.com',
    },
    attributesCompareTo: {
      'Email domain name': 'test.com',
    },
    style: IrmaCardStyle.normal,
  );

  // Close the dialog
  final okButtonFinder = find.text('OK');
  await tester.ensureVisible(okButtonFinder);
  await tester.pumpAndSettle();
  await tester.tapAndSettle(okButtonFinder);

  await tester.tapAndSettle(find.text('Obtain data'));
  expect(find.byType(AddDataDetailsScreen), findsOneWidget);

  // Now issue the correct right credential
  await issueCredentials(tester, irmaBinding, {
    'irma-demo.sidn-pbdf.email.email': 'test@test.com',
    'irma-demo.sidn-pbdf.email.domain': 'test.com',
  });

  // Issue wizard should be completed now
  expect(find.text('All required data has been added'), findsOneWidget);

  // Check the credential card now that is has been completed
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation',
    attributes: {},
    style: IrmaCardStyle.normal,
  );

  await tester.tapAndSettle(find.text('Next step'));

  // Expect the choices screen
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
  expect(
    find.text('This data has already been added to your app. Verify that the data is still correct.'),
    findsOneWidget,
  );

  // The already added municipality should appear now
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

  // Continue to choices overview
  await tester.tapAndSettle(find.text('Next step'));

  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
  expect(find.text('Share my data with demo.privacybydesign.foundation'), findsOneWidget);

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
    issuerName: 'Demo Privacy by Design Foundation',
    attributes: {
      'Email address': 'test@test.com',
      'Email domain name': 'test.com',
    },
    style: IrmaCardStyle.normal,
  );

  await tester.tapAndSettle(find.text('Share data'));
  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}
