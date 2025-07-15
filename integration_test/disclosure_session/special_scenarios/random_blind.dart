import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_issue_wizard_screen.dart';
import 'package:irmamobile/src/screens/session/session_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card_attribute_list.dart';
import 'package:irmamobile/src/widgets/irma_quote.dart';

import '../../helpers/helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> randomBlindTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Start random blind signature session
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/signature/v2",
          "message": "Message to be signed by user",
          "disclose": [
            [
              [ "irma-demo.stemmen.stempas.votingnumber" ]
            ]
          ]
        }
      ''';
  await irmaBinding.repository.startTestSession(sessionRequest);

  await evaluateIntroduction(tester);

  expect(find.byType(DisclosurePermissionIssueWizardScreen), findsOneWidget);

  expect(
    find.text('This data cannot be obtained. Please contact Demo Voting Card Issuer to obtain this data.'),
    findsOneWidget,
  );

  await tester.tapAndSettle(find.text('Close'));

  // Session flow should be over now
  expect(find.byType(SessionScreen), findsNothing);

  // Issue a stempas credential
  await issueCredentials(tester, irmaBinding, {
    'irma-demo.stemmen.stempas.election': 'Test election',
    'irma-demo.stemmen.stempas.voteURL': 'test-election.nl',
    'irma-demo.stemmen.stempas.start': '01-08-2023',
    'irma-demo.stemmen.stempas.end': '31-08-2023',
  });

  final okButtonFinder = find.text('OK');
  await tester.tapAndSettle(okButtonFinder);

  // Start random blind signature session again
  await irmaBinding.repository.startTestSession(sessionRequest);

  // The introduction is shown again because the last session was cancelled
  await evaluateIntroduction(tester);

  // We should go straight to the overview screen.
  final overViewScreenFinder = find.byType(DisclosurePermissionChoicesScreen);
  expect(overViewScreenFinder, findsOneWidget);

  // The signable message should be present
  final quoteFinder = find.byKey(const Key('signature_message'));
  expect(quoteFinder, findsOneWidget);

  final actualQuoteText = (quoteFinder.evaluate().first.widget as IrmaQuote).quote;
  const expectedQuoteText = 'Message to be signed by user';
  expect(actualQuoteText, expectedQuoteText);

  // One IrmaCredentialCard should be present
  final credentialCardFinder = find.byType(IrmaCredentialCard);
  expect(credentialCardFinder, findsOneWidget);

  // The credential should be a stempas credential
  await evaluateCredentialCard(
    tester,
    credentialCardFinder,
    credentialName: 'Demo Voting Card',
    issuerName: 'Demo Voting Card Issuer',
  );

  // And it should have a anonymous voting number
  // in the attribute list
  final cardAttList = find.descendant(of: credentialCardFinder, matching: find.byType(IrmaCredentialCardAttributeList));

  final cardAttListText = tester.getAllText(cardAttList);
  final firstAttributeName = cardAttListText.first;
  const expectedFirstAttributeName = 'Anonymous voting number';
  expect(firstAttributeName, expectedFirstAttributeName);

  final confirmButtonFinder = find.text('Sign and share');
  await tester.tapAndSettle(confirmButtonFinder);

  await evaluateShareDialog(tester, isSignatureSession: true);

  await evaluateFeedback(tester, isSignatureSession: true);
}
