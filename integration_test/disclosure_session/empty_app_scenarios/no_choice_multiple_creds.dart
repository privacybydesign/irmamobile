import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/add_data/add_data_details_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_discon_stepper.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> noChoiceMultipleCredsTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Email AND mobile number
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email"]
            ],
            [
              [ "irma-demo.sidn-pbdf.mobilenumber.mobilenumber"]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  // First, the missing credentials should be obtainable
  expect(find.text('Collect data'), findsOneWidget);

  // We should have one discon stepper
  final disConStepperFinder = find.byType(DisclosureDisconStepper);
  expect(disConStepperFinder, findsOneWidget);

  // The discon stepper should consist of two cards
  final cardsFinder = find.descendant(
    of: disConStepperFinder,
    matching: find.byType(IrmaCredentialCard),
  );
  expect(cardsFinder, findsNWidgets(2));

  // First card should be highlighted, second card should be normal
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    style: IrmaCardStyle.highlighted,
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: 'Demo Mobile phone number',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    style: IrmaCardStyle.normal,
  );

  // Continue and expect the AddDataDetailsScreen
  await tester.tapAndSettle(find.text('Obtain data'));
  expect(find.byType(AddDataDetailsScreen), findsOneWidget);

  // Issue the email credential
  await issueEmailAddress(tester, irmaBinding);

  // Now only the second card should be highlighted
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    style: IrmaCardStyle.normal,
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: 'Demo Mobile phone number',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    style: IrmaCardStyle.highlighted,
  );

  await issueMobileNumber(tester, irmaBinding);

  // Issue wizard should be completed
  expect(find.text('All required data has been added'), findsOneWidget);
  await tester.tapAndSettle(find.text('Next step'));

  // Expect the choices screen
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
  await tester.tapAndSettle(find.text('Share data'));

  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}
