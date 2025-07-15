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

Future<void> filledSpecificAttributeValuesNoMatchTest(
    WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueDemoCredentials(tester, irmaBinding);

  // Email address where domain has to be test.com
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email", { "type" : "irma-demo.sidn-pbdf.email.domain", "value": "sidn.nl" }  ]
            ]
          ]
        }
      ''';
  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  // Expect obtain credential screen
  expect(find.byType(DisclosurePermissionIssueWizardScreen), findsOneWidget);
  expect(find.text('Obtain my data step by step and share it with the requesting party after that'), findsOneWidget);

  final cardsFinder = find.byType(IrmaCredentialCard);
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Email domain name': 'sidn.nl',
    },
    attributesCompareTo: {
      'Email domain name': 'sidn.nl',
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
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Email domain name': 'demo.com',
    },
    attributesCompareTo: {
      'Email domain name': 'sidn.nl',
    },
    style: IrmaCardStyle.normal,
  );
  await evaluateCredentialCard(
    tester,
    dialogCardsFinder.at(1),
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Email domain name': 'sidn.nl',
    },
    attributesCompareTo: {
      'Email domain name': 'sidn.nl',
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
    'irma-demo.sidn-pbdf.email.email': 'test@sidn.nl',
    'irma-demo.sidn-pbdf.email.domain': 'sidn.nl',
  });

  // Issue wizard should be completed now
  expect(find.text('All required data has been added'), findsOneWidget);

  // Check the credential card now that is has been completed
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {},
    style: IrmaCardStyle.normal,
  );

  await tester.tapAndSettle(find.text('Next step'));

  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);
  expect(find.text('Share my data with demo.privacybydesign.foundation'), findsOneWidget);

  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Email address': 'test@sidn.nl',
      'Email domain name': 'sidn.nl',
    },
    style: IrmaCardStyle.normal,
  );

  await tester.tapAndSettle(find.text('Share data'));

  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}
