import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/session/session_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/issuance_permission.dart';
import 'package:irmamobile/src/screens/session/widgets/issuance_success_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> combinedDisclosureIssuanceSessionTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding);

  // Email address
  // And receiving the  irma-demo.sidn-pbdf.uniqueid credential
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/issuance/v2",
          "credentials": [{
              "credential" : "irma-demo.sidn-pbdf.uniqueid",
              "attributes": {
                "uniqueid": "1234",
                "organization": "E-mail guild"
              }
            }],
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ]
            ]
          ]
        }
      ''';

  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  await tester.tapAndSettle(find.text('Share data'));
  await evaluateShareDialog(tester);

  // Expect add data screen
  expect(find.byType(IssuancePermission), findsOneWidget);

  final cardsFinder = find.byType(IrmaCredentialCard);
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: 'Demo Login data',
    issuerName: 'Demo Privacy by Design Foundation',
    attributes: {
      'Login code': '1234',
      'Organization': 'E-mail guild',
    },
    style: IrmaCardStyle.normal,
  );

  // Tap add data button
  await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));

  final successScreenFinder = find.byType(IssuanceSuccessScreen);
  expect(successScreenFinder, findsOneWidget);

  await tester.tapAndSettle(find.text('OK'));

  expect(find.byType(SessionScreen), findsNothing);
}
