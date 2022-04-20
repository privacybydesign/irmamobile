// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/screens/activity/activity_detail_screen.dart';
import 'package:irmamobile/src/screens/activity/activity_tab.dart';
import 'package:irmamobile/src/screens/activity/widgets/activity_card.dart';
import 'package:irmamobile/src/screens/activity/widgets/activity_detail_issuance.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card_attribute_list.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credentials_card.dart';

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
        // Initialize the app for integration tests
        await tester.pumpWidgetAndSettle(IrmaApp(repository: irmaBinding.repository));
        await unlock(tester);

        // Start issuance session
        await issueCardsMunicipality(tester, irmaBinding);

        // Navigate to activty tab
        await tester.tapAndSettle(find.byKey(const Key('nav_button_activity')));
        expect(find.byType(ActivityTab), findsOneWidget);

        // Check if the activity cards are displayed
        final activityCards = tester.widgetList(find.byType(ActivityCard));
        expect(activityCards.length, 2);

        // Tap on the Demo Municipality card
        await tester.tapAndSettle(find.text('Demo Municipality'));

        // Check if the correct detail screen is rendered
        expect(find.byType(ActivityDetailScreen), findsOneWidget);
        expect(find.byType(ActivityDetailIssuance), findsOneWidget);

        // Get all the text in the attribute list
        final cardAttributes = tester
            .getAllText(find.descendant(
              of: tester.findByTypeWithContent(type: IrmaCredentialsCard, content: find.text('Demo Personal data')),
              matching: find.byType(IrmaCredentialCardAttributeList),
            ))
            .toList();

        // Assert if the values are present
        expect(
            cardAttributes,
            containsAll([
              'Full name',
              'W.L. de Bruijn',
              'Initials',
              'W.L.',
              'First names',
              'Willeke Liselotte',
              'Prefix',
              'de',
              'Surname',
              'de Bruijn',
              'Family name',
              'Bruijn',
              'Gender',
              'V',
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
              'Dutch nationality',
              'Yes',
              'City of birth',
              'Amsterdam',
              'Country of birth',
              'Nederland',
              'BSN',
              '999999990',
              'Assurance level',
              'Substantieel',
            ]));

        // Check the address card.
        // Get all the text in the attribute list
        final personalCardAttributes = tester
            .getAllText(find.descendant(
              of: tester.findByTypeWithContent(type: IrmaCredentialsCard, content: find.text('Demo Address')),
              matching: find.byType(IrmaCredentialCardAttributeList),
            ))
            .toList();

        // Assert if the values are present
        expect(
            personalCardAttributes,
            containsAll([
              'Street',
              'Meander',
              'House number',
              '501',
              'Postal code',
              '1234AB',
              'City',
              'Arnhem',
              'Municipality',
              'Arnhem',
            ]));

        // Return to the home
        await tester.tapAndSettle(find.text('Back'));
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );
  });
}
