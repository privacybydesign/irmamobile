import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/activity/activity_tab.dart';
import 'package:irmamobile/src/screens/activity/widgets/activity_card.dart';
import 'package:irmamobile/src/screens/add_data/add_data_details_screen.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_empty_credential_card.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

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
  await evaluateIntroduction(tester);

  expect(find.text('No data selected'), findsOneWidget);

  // Try to add optional data.
  final addOptionalDataButton = find.text('Add optional data').hitTestable();
  await tester.scrollUntilVisible(addOptionalDataButton, 50);
  await tester.tapAndSettle(addOptionalDataButton);

  expect(find.text('Demo Email address'), findsOneWidget);

  // Continue and expect the AddDataDetailsScreen
  await tester.tapAndSettle(find.text('Obtain data'));
  expect(find.byType(AddDataDetailsScreen), findsOneWidget);

  // We cannot actually press the 'Obtain data' button, because we get redirected to an external flow then.
  // Therefore, we mock this behaviour using the helper below until we have a better solution.
  await issueEmailAddress(tester, irmaBinding);
  await tester.tapAndSettle(find.text('Done'));

  // Delete optional data from selection again.
  final deleteOptionalDataButton = find.descendant(
    of: find.byType(IrmaCredentialCard),
    matching: find.byIcon(Icons.close).hitTestable(),
  );
  await tester.scrollUntilVisible(
    deleteOptionalDataButton.hitTestable(),
    50,
  );
  await tester.tapAndSettle(deleteOptionalDataButton);

  await tester.tapAndSettle(
    find.text('Share data'),
  );

  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);

  // Start session again to validate that now email is pre-selected.
  await irmaBinding.repository.startTestSession(sessionRequest);

  await tester.waitFor(find.text('Share my data'));
  expect(find.text('Optional data'), findsOneWidget);

  await evaluateCredentialCard(
    tester,
    find.byType(IrmaCredentialCard).first,
    credentialName: 'Demo Email address',
    issuerName: 'Demo Privacy by Design Foundation via SIDN',
    attributes: {
      'Email address': 'test@example.com',
    },
  );
  await tester.tapAndSettle(
    find.text('Share data'),
  );

  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);

  // Navigate to to activity tab
  expect(find.byType(HomeScreen), findsOneWidget);
  await tester.tap(find.byKey(const Key('nav_button_activity')));
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(ActivityTab), findsOneWidget);

  // Tap the second activity card.
  // That's the session that is completely empty.
  final secondActivityCardFinder = find.byType(ActivityCard).at(1).hitTestable();
  await tester.scrollUntilVisible(secondActivityCardFinder, 50);
  await tester.tapAndSettle(
    secondActivityCardFinder,
  );

  // Expect the no data card
  expect(
    find.byType(IrmaEmptyCredentialCard),
    findsOneWidget,
  );
}
