import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_choices_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';
import 'package:irmamobile/src/widgets/irma_quote.dart';
import 'package:irmamobile/src/widgets/requestor_header.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> signingTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding);

  // Email address
  // And signing the message: "Message to be signed by user"
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/signature/v2",
          "message": "Message to be signed by user",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ]
            ]
          ]
        }
      ''';
  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  expect(find.byType(DisclosurePermissionChoicesScreen), findsOneWidget);

  final requestorHeaderFinder = find.byType(RequestorHeader);
  await evaluateRequestorHeader(
    tester,
    requestorHeaderFinder,
    localizedRequestorName: 'demo.privacybydesign.foundation',
    isVerified: false,
  );

  expect(find.text("This is the message you're signing:"), findsOneWidget);
  final quoteFinder = find.byKey(const Key('signature_message'));
  expect(quoteFinder, findsOneWidget);
  expect(
    (quoteFinder.evaluate().first.widget as IrmaQuote).quote,
    'Message to be signed by user',
  );

  expect(find.text('Share my data with is.demo.staging.yivi.app'), findsOneWidget);

  final cardsFinder = find.byType(IrmaCredentialCard);
  expect(cardsFinder, findsOneWidget);
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

  await tester.tapAndSettle(find.text('Sign and share'));

  await evaluateShareDialog(
    tester,
    isSignatureSession: true,
  );
  await evaluateFeedback(
    tester,
    isSignatureSession: true,
  );
}
