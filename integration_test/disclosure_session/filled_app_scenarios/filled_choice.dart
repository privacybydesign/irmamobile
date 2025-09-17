import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/add_data/add_data_details_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_make_choice_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';
import 'package:irmamobile/src/widgets/requestor_header.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> filledChoiceTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueDemoCredentials(tester, irmaBinding);

  // Session requesting:
  // Email OR
  // Mobile number
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ],
              [ "irma-demo.sidn-pbdf.mobilenumber.mobilenumber" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  // Expect the choices screen
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

  // Expect one credential card to be present
  final cardFinder = find.byType(IrmaCredentialCard);
  expect(cardFinder, findsOneWidget);

  // Card should be filled and have correct header
  await evaluateCredentialCard(
    tester,
    cardFinder,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Email address': 'test@example.com',
    },
    style: IrmaCardStyle.normal,
  );

  // Change choice should be visible
  final changeChoiceFinder = find.text('Change choice');
  await tester.scrollUntilVisible(changeChoiceFinder.hitTestable(), 50);
  expect(changeChoiceFinder, findsOneWidget);

  // Press the change choice
  await tester.tapAndSettle(changeChoiceFinder);

  // Expect make choice screen
  expect(find.byType(DisclosurePermissionMakeChoiceScreen), findsOneWidget);

  // This screen to have three options
  expect(cardFinder, findsNWidgets(3));

  // The first card should be select
  await evaluateCredentialCard(
    tester,
    cardFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Email address': 'test@example.com',
    },
    isSelected: true,
  );

  // The second card should show a template credential
  await evaluateCredentialCard(
    tester,
    cardFinder.at(1),
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {},
    isSelected: false,
  );

  // The third card should show a template credential too
  final thirdCardFinder = cardFinder.at(2);
  await tester.scrollUntilVisible(
    thirdCardFinder.hitTestable(),
    50,
  );
  await evaluateCredentialCard(
    tester,
    thirdCardFinder,
    credentialName: 'Demo Mobile phone number',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {},
    isSelected: false,
  );

  // Select the obtain mobile number
  await tester.tapAndSettle(thirdCardFinder);

  // Card should be selected now
  await evaluateCredentialCard(
    tester,
    thirdCardFinder,
    isSelected: true,
  );

  await tester.tapAndSettle(find.text('Obtain data'));
  expect(find.byType(AddDataDetailsScreen), findsOneWidget);

  await issueMunicipalityPersonalData(tester, irmaBinding);
  await issueMobileNumber(tester, irmaBinding);

  // Now four cards should be visible
  expect(cardFinder, findsNWidgets(4));

  // Check if all cards display the correct
  await evaluateCredentialCard(
    tester,
    cardFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Email address': 'test@example.com',
    },
    isSelected: false,
  );
  await evaluateCredentialCard(
    tester,
    cardFinder.at(1),
    credentialName: 'Demo Mobile phone number',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Mobile phone number': '0612345678',
    },
    isSelected: true,
  );

  await evaluateCredentialCard(
    tester,
    cardFinder.at(2),
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {},
    isSelected: false,
  );
  await evaluateCredentialCard(
    tester,
    cardFinder.at(3),
    credentialName: 'Demo Mobile phone number',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {},
    isSelected: false,
  );

  // Confirm choice
  await tester.tapAndSettle(find.text('Done'));
  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

  final requestorHeaderFinder = find.byType(RequestorHeader);
  await evaluateRequestorHeader(
    tester,
    requestorHeaderFinder,
    localizedRequestorName: 'is.demo.staging.yivi.app',
    isVerified: false,
  );

  // Only selected card should remain
  await evaluateCredentialCard(
    tester,
    cardFinder.first,
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
