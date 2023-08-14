import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';

import '../../helpers/helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> filledNoChoiceSameCredsTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Issue two different email addresses
  await issueCredentials(tester, irmaBinding, {
    'irma-demo.sidn-pbdf.email.email': 'first-email@example.com',
    'irma-demo.sidn-pbdf.email.domain': 'example.com',
  });

  await issueCredentials(tester, irmaBinding, {
    'irma-demo.sidn-pbdf.email.email': 'second-email@example.com',
    'irma-demo.sidn-pbdf.email.domain': 'example.com',
  });

  // Session requesting:
  // Only email
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present
  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  // Find and press change choice
  final changeChoiceFinder = find.text('Change choice');
  await tester.scrollUntilVisible(
    changeChoiceFinder.hitTestable(),
    50,
  );
  await tester.tapAndSettle(changeChoiceFinder);

  final credentialCardsFinder = find.byType(IrmaCredentialCard);
  const demoEmailCredentialName = 'Demo Email address';
  const demoEmailIssuerName = 'Demo Privacy by Design Foundation via SIDN';

  await evaluateCredentialCard(
    tester,
    credentialCardsFinder.first,
    isSelected: true,
    credentialName: demoEmailCredentialName,
    issuerName: demoEmailIssuerName,
    attributes: {
      'Email address': 'first-email@example.com',
    },
  );

  final secondCredentialCard = credentialCardsFinder.at(1);
  await evaluateCredentialCard(
    tester,
    secondCredentialCard,
    isSelected: false,
    credentialName: demoEmailCredentialName,
    issuerName: demoEmailIssuerName,
    attributes: {
      'Email address': 'second-email@example.com',
    },
  );

  // Scroll to the second credential
  await tester.scrollUntilVisible(
    secondCredentialCard,
    50,
  );

  // Select the second credential
  await tester.tapAndSettle(secondCredentialCard);

  // Second credential should be selected now
  await evaluateCredentialCard(
    tester,
    secondCredentialCard,
    isSelected: true,
  );

  // Press done
  final doneButterFinder = find.text('Done').hitTestable();
  await tester.tapAndSettle(doneButterFinder);

  // Expect to be on the overview screen
  final overviewScreenFinder = find.byType(DisclosurePermissionChoicesScreen);
  expect(overviewScreenFinder, findsOneWidget);

  // The only credential on the overview should be the second email
  await evaluateCredentialCard(
    tester,
    credentialCardsFinder.first,
    credentialName: demoEmailCredentialName,
    issuerName: demoEmailIssuerName,
    attributes: {
      'Email address': 'second-email@example.com',
    },
  );

  // Finish the flow
  await tester.tapAndSettle(find.text('Share data'));
  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}
