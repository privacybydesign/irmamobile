import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/add_data/add_data_details_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_discon_stepper.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_issue_wizard_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_make_choice_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> filledNoChoiceMultipleCredsTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueDemoCredentials(tester, irmaBinding);

  // Session requesting:
  // Email AND mobile number
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ]
            ],
            [
              [ "irma-demo.sidn-pbdf.mobilenumber.mobilenumber" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present
  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  // Expect obtain credential screen
  expect(find.byType(DisclosurePermissionIssueWizardScreen), findsOneWidget);
  expect(find.text('Obtain my data step by step and share it with the requesting party after that'), findsOneWidget);

  // One stepper should be visible
  expect(find.byType(DisclosureDisconStepper), findsOneWidget);

  // One Credential card should be visible
  final cardsFinder = find.byType(IrmaCredentialCard);
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Mobile phone number',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {},
    style: IrmaCardStyle.highlighted,
  );

  await tester.tapAndSettle(find.text('Obtain data'));
  expect(find.byType(AddDataDetailsScreen), findsOneWidget);

  await issueMunicipalityPersonalData(tester, irmaBinding);

  await tester.tapAndSettle(find.text('Obtain data'));
  expect(find.byType(AddDataDetailsScreen), findsOneWidget);

  await issueMobileNumber(tester, irmaBinding);

  // Card styling should change
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    style: IrmaCardStyle.normal,
  );

  // Continue
  await tester.tapAndSettle(find.text('Next step'));

  // Expect the choices screen
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

  // With the correct header
  expect(
    find.text('This data has already been added to your app. Verify that the data is still correct.'),
    findsOneWidget,
  );

  // One card should be visible here too
  expect(cardsFinder, findsOneWidget);

  // The card should show the previously obtained credential
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Email address': 'test@example.com',
    },
    style: IrmaCardStyle.normal,
  );

  // Change choice should be visible
  final changeChoiceFinder = find.text('Change choice');
  await tester.scrollUntilVisible(
    changeChoiceFinder.hitTestable(),
    50,
  );

  // Press the change choice
  await tester.tapAndSettle(changeChoiceFinder);

  // Expect make choice screen
  expect(find.byType(DisclosurePermissionMakeChoiceScreen), findsOneWidget);

  // This screen should show two options
  expect(cardsFinder, findsNWidgets(2));

  // The card should show the previously obtained credential,
  // with highlighted styling
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Email address': 'test@example.com',
    },
  );

  // Second card should be a template card
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {},
  );

  // Press go back
  await tester.tapAndSettle(find.byKey(const Key('irma_app_bar_leading')));

  // Expect the choices screen
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

  // Continue to overview
  await tester.tapAndSettle(find.text('Next step'));

  // The overview also uses the ChoicesScreen. Expect it one more time.
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

  // The title should have changed though
  expect(find.text('Share my data with demo.privacybydesign.foundation'), findsOneWidget);

  // Now two filled cards should be visible
  expect(cardsFinder, findsNWidgets(2));
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Email address': 'test@example.com',
    },
    style: IrmaCardStyle.normal,
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: 'Demo Mobile phone number',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Mobile phone number': '0612345678',
    },
    style: IrmaCardStyle.normal,
  );

  await tester.tapAndSettle(find.text('Share data'));
  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}
