// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';

import 'helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('session', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('disclose-if-present', (tester) async {
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp(
        repository: irmaBinding.repository,
        forcedLocale: const Locale('en'),
      ));

      await unlock(tester);

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
      // TODO: attribute order is wrong (IRMA-2073)
      await issueCredentials(tester, irmaBinding, {
        'irma-demo.sidn-pbdf.email.domain': 'example.com',
        'irma-demo.sidn-pbdf.email.email': 'test@example.com',
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
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('optional-disjunction', (tester) async {
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp(
        repository: irmaBinding.repository,
        forcedLocale: const Locale('en'),
      ));

      await unlock(tester);

      // First, make sure the mobile number credential is present.
      await issueCredentials(tester, irmaBinding, {
        'irma-demo.sidn-pbdf.mobilenumber.mobilenumber': '+31612345678',
      });

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
      await tester.waitFor(find.text('Share your data in 3 simple steps:'));
      await tester.tapAndSettle(find.descendant(of: find.byType(IrmaButton), matching: find.text('Get going')));

      // First, the missing required disjunctions should be obtained using an issue wizard.
      expect(find.text('Collect data'), findsOneWidget);
      expect(tester.widgetList(find.byType(IrmaCredentialCard)).length, 1);
      expect(find.text('Demo Email address'), findsOneWidget);

      // We cannot actually press the 'Obtain data' button, because we get redirected to an external flow then.
      // Therefore, we mock this behaviour using the helper below until we have a better solution.
      // TODO: attribute order is wrong (IRMA-2073)
      await issueCredentials(tester, irmaBinding, {
        'irma-demo.sidn-pbdf.email.domain': 'example.com',
        'irma-demo.sidn-pbdf.email.email': 'test@example.com',
      });
      expect(find.text('All required data has been added.'), findsOneWidget);

      // Complete issue wizard
      await tester.tapAndSettle(find.text('Next step'));
      expect(find.text('Validate data'), findsOneWidget);
      expect(find.text('This data has already been added to the app:'), findsOneWidget);
      expect(find.text('No data selected'), findsOneWidget);

      // Try to add optional data.
      final addOptionalDataButton = find.text('Add optional data').hitTestable();
      await tester.scrollUntilVisible(addOptionalDataButton, 50);
      await tester.tapAndSettle(addOptionalDataButton);

      // There should be three options: the option we added at the beginning of this test and two template options
      // to obtain new mobile number credential instances for either pbdf or sidn-pbdf.
      expect(find.text('Demo Mobile phone number'), findsNWidgets(3));
      expect(find.text('Demo Privacy by Design Foundation via SIDN'), findsNWidgets(2));
      expect(find.text('Demo Privacy by Design Foundation'), findsOneWidget);
      expect(find.text('+31612345678'), findsOneWidget);

      // Select the mobile phone number that we added at the beginning of this test.
      await tester.tapAndSettle(find.text('Done'));
      expect(find.text('Validate data'), findsOneWidget);
      expect(find.text('This data has already been added to the app:'), findsOneWidget);
      expect(find.text('Demo Mobile phone number'), findsOneWidget);
      expect(find.text('Demo Privacy by Design Foundation via SIDN'), findsOneWidget);
      expect(find.text('+31612345678'), findsOneWidget);

      // Continue to the disclosure permission overview screen.
      await tester.tapAndSettle(find.text('Next step'));
      expect(find.text('Share your data'), findsOneWidget);
      expect(find.text('This is the data you are going to share:'), findsOneWidget);
      expect(find.text('Demo Email address'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('example.com'), findsOneWidget);
      expect(find.text('Demo Mobile phone number'), findsOneWidget);
      expect(find.text('+31612345678'), findsOneWidget);

      // Finish session.
      await tester.tapAndSettle(find.text('Share data'));
      await tester.tapAndSettle(find.text('Share'));

      await tester.waitFor(find.text('Success'));
      await tester.tapAndSettle(find.text('OK'));

      expect(find.byType(HomeScreen).hitTestable(), findsOneWidget);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
