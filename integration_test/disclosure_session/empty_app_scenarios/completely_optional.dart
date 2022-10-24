import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';

import '../../helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';

Future<void> completelyOptionalTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Scenario requesting:
  // E-mail address OR nothing
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ],
              []
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // Dismiss introduction screen.
  await tester.waitFor(find.text('Share your data in 3 simple steps:'));
  await tester.tapAndSettle(find.descendant(of: find.byType(IrmaButton), matching: find.text('Get going')));

  expect(find.text('This is the data you are going to share:'), findsOneWidget);
  expect(find.text('No data selected'), findsOneWidget);

  // Try to add optional data.
  final addOptionalDataButton = find.text('Add optional data').hitTestable();
  await tester.scrollUntilVisible(addOptionalDataButton, 50);
  await tester.tapAndSettle(addOptionalDataButton);

  expect(find.text('Demo Email address'), findsOneWidget);

  // We cannot actually press the 'Obtain data' button, because we get redirected to an external flow then.
  // Therefore, we mock this behaviour using the helper below until we have a better solution.
  await issueCredentials(tester, irmaBinding, {
    'irma-demo.sidn-pbdf.email.email': 'test@example.com',
    'irma-demo.sidn-pbdf.email.domain': 'example.com',
  });

  await tester.tapAndSettle(find.text('Done'));

  // Delete optional data from selection again.
  final deleteOptionalDataButton = find.descendant(
    of: find.byType(IrmaCredentialCard),
    matching: find.byIcon(Icons.close).hitTestable(),
  );
  await tester.scrollUntilVisible(deleteOptionalDataButton, 50);
  await tester.tapAndSettle(deleteOptionalDataButton);

  // Finish session.
  await tester.tapAndSettle(find.text('Share data'));
  await tester.tapAndSettle(find.text('Share'));

  await tester.waitFor(find.text('Success'));
  await tester.tapAndSettle(find.text('OK'));

  expect(find.byType(HomeScreen).hitTestable(), findsOneWidget);

  // Start session again to validate that now email is pre-selected.
  await irmaBinding.repository.startTestSession(sessionRequest);
  await tester.waitFor(find.text('Share your data'));
  expect(find.text('This is the data you are going to share:'), findsOneWidget);
  expect(find.text('Demo Email address'), findsOneWidget);
  expect(find.text('test@example.com'), findsOneWidget);

  // Finish session.
  await tester.tapAndSettle(find.text('Share data'));
  await tester.tapAndSettle(find.text('Share'));

  await tester.waitFor(find.text('Success'));
  await tester.tapAndSettle(find.text('OK'));

  expect(find.byType(HomeScreen).hitTestable(), findsOneWidget);
}