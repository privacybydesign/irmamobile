import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/add_data/add_data_details_screen.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';

Future<void> filledOptionalDisjunctionTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Issue number from irma-demo.sidn-pbdf
  await issueMobileNumber(tester, irmaBinding);

  // Start session
  await irmaBinding.repository.startTestSession('''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email", "irma-demo.sidn-pbdf.email.domain" ]
            ],
            [
              [],
              [ "irma-demo.pbdf.mobilenumber.mobilenumber" ],
              [ "irma-demo.sidn-pbdf.mobilenumber.mobilenumber" ]
            ]
          ]
        }
      ''');

  // Dismiss introduction screen.
  await tester.waitFor(find.text('Share your data'));
  await tester.tapAndSettle(find.descendant(of: find.byType(IrmaButton), matching: find.text('Get going')));

  // First, the missing required disjunctions should be obtained using an issue wizard.
  expect(find.text('Collect data'), findsOneWidget);

  final cardsFinder = find.byType(IrmaCredentialCard);
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {},
    style: IrmaCardStyle.highlighted,
  );

  await tester.tapAndSettle(find.text('Obtain data'));
  expect(find.byType(AddDataDetailsScreen), findsOneWidget);

  // We cannot actually press the 'Obtain data' button, because we get redirected to an external flow then.
  // Therefore, we mock this behaviour using the helper below until we have a better solution.
  await issueEmailAddress(tester, irmaBinding);

  expect(find.text('All required data has been added.'), findsOneWidget);

  // Complete issue wizard
  await tester.tapAndSettle(find.text('Next step'));
  expect(find.text('Validate data'), findsOneWidget);
  expect(find.text('This data was previously added to the app:'), findsOneWidget);
  expect(find.text('No data selected'), findsOneWidget);

  // Try to add optional data.
  final addOptionalDataButton = find.text('Add optional data').hitTestable();
  await tester.scrollUntilVisible(addOptionalDataButton, 50);
  await tester.tapAndSettle(addOptionalDataButton);

  // There should be three options: the option we added at the beginning of this test and two template options
  // to obtain new mobile number credential instances for either pbdf or sidn-pbdf.
  expect(cardsFinder, findsNWidgets(3));

  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Mobile phone number',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Mobile phone number': '0612345678',
    },
    style: IrmaCardStyle.highlighted,
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: 'Demo Mobile phone number',
    issuerName: 'Demo Privacy by Design Foundation',
    attributes: {},
    style: IrmaCardStyle.outlined,
  );
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(2),
    credentialName: 'Demo Mobile phone number',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {},
    style: IrmaCardStyle.outlined,
  );

  // Select the mobile phone number that we added at the beginning of this test.
  await tester.tapAndSettle(find.text('Done'));
  expect(find.text('Validate data'), findsOneWidget);
  expect(find.text('This data was previously added to the app:'), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Mobile phone number',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Mobile phone number': '0612345678',
    },
    style: IrmaCardStyle.normal,
  );

  // Continue to the disclosure permission overview screen.
  await tester.tapAndSettle(find.text('Next step'));

  expect(find.text('Share my data'), findsOneWidget);
  expect(find.text('This is the data you are going to share:'), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Email address': 'test@example.com',
      'Email domain name': 'example.com',
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

  // Finish session.
  await tester.tapAndSettle(find.text('Share data'));
  await tester.tapAndSettle(find.text('Share'));

  await tester.waitFor(find.text('Success'));
  await tester.tapAndSettle(find.text('OK'));

  expect(find.byType(HomeScreen).hitTestable(), findsOneWidget);
}
