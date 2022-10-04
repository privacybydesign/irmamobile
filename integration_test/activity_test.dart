// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:irmamobile/src/screens/activity/activity_detail_screen.dart';
import 'package:irmamobile/src/screens/activity/widgets/activity_detail_issuance.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card_attribute_list.dart';

import 'helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('activity', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets(
      'issuance',
      (tester) async {
        await pumpAndUnlockApp(tester, irmaBinding.repository);

        await tester.tap(find.byKey(const Key('nav_button_activity')));
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('No activities were logged.'), findsOneWidget);

        await issueMunicipalityCards(tester, irmaBinding);

        await tester.tap(find.byKey(const Key('nav_button_activity')));
        await tester.pump(const Duration(seconds: 1));

        // Tap on the Demo Municipality card
        await tester.tapAndSettle(find.text('Demo Municipalities'));

        // Check if the correct detail screen is rendered
        expect(find.byType(ActivityDetailScreen), findsOneWidget);
        expect(find.byType(ActivityDetailIssuance), findsOneWidget);

        // Expect headers
        expect(find.text('Activity'), findsOneWidget);
        expect(find.text('Received data'), findsOneWidget);

        // Get all the text in the attribute list
        final cardAttributes = tester
            .getAllText(find.descendant(
              of: tester.findByTypeWithContent(
                type: IrmaCredentialCard,
                content: find.text('Demo Personal data'),
              ),
              matching: find.byType(IrmaCredentialCardAttributeList),
            ))
            .toList();

        // Assert if the values are present and sorted correctly
        expect(
          cardAttributes,
          [
            'Initials',
            'W.L.',
            'First names',
            'Willeke Liselotte',
            'Prefix',
            'de',
            'Family name',
            'Bruijn',
            'Full name',
            'W.L. de Bruijn',
            'Gender',
            'V',
            'Dutch nationality',
            'Yes',
            'Surname',
            'de Bruijn',
            'Date of birth',
            '10-04-1965',
            'Over 12',
            'Yes',
            'Over 16',
            'Yes',
            'Over 18',
            'Yes',
            'Over 21',
            'Yes',
            'Over 65',
            'No',
            'BSN',
            '999999990',
            'DigiD assurance level',
            'Substantieel',
          ],
        );

        // Find the activity timestamp
        final timestampFinder = find.byKey(const Key('activity_timestamp'));
        await tester.scrollUntilVisible(timestampFinder, 50);
        expect(timestampFinder, findsOneWidget);
      },
      timeout: const Timeout(
        Duration(minutes: 1),
      ),
    );
  });
}
