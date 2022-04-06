// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/main.dart';
// import 'package:irmamobile/src/widgets/card/card.dart';
// import 'package:irmamobile/src/widgets/card/card_attributes.dart';

import 'helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  //TODO: These tests need to be updated for the UX 2.0 screens
  group('history', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('screen-check-issuance', (tester) async {
      // Scenario 1 of IRMA app11 settings
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp(repository: irmaBinding.repository));
      await unlock(tester);
      // Start session
      await issueCardsMunicipality(tester, irmaBinding);
      // Open menu
      await tester.tapAndSettle(find.byKey(const Key('open_menu_icon')));
      // Open history
      await tester.tapAndSettle(find.text('History'));
      //final logEntryCards = tester.widgetList(find.byType(LogEntryCard));
      //expect(logEntryCards.length, 2);
      // Tap on the Demo Municipality card
      await tester.tapAndSettle(find.text('Demo Municipality'));
      // Check the personal data card on the log entry's detailScreen.
      // final cardAttributes = tester.getAllText(find.descendant(
      //   of: tester.findByTypeWithContent(type: IrmaCard, content: find.text('Demo Personal data')),
      //   matching: find.byType(CardAttributes),
      // ));
      // expect(cardAttributes, [
      //   'Full name',
      //   'W.L. de Bruijn',
      //   'Initials',
      //   'W.L.',
      //   'First names',
      //   'Willeke Liselotte',
      //   'Prefix',
      //   'de',
      //   'Surname',
      //   'de Bruijn',
      //   'Family name',
      //   'Bruijn',
      //   'Gender',
      //   'V',
      //   'Date of birth',
      //   '10-04-1965',
      //   'Over 12',
      //   'Yes',
      //   'Over 16',
      //   'Yes',
      //   'Over 18',
      //   'Yes',
      //   'Over 21',
      //   'Yes',
      //   'Over 65',
      //   'No',
      //   'Dutch nationality',
      //   'Yes',
      //   'City of birth',
      //   'Amsterdam',
      //   'Country of birth',
      //   'Nederland',
      //   'BSN',
      //   '999999990',
      //   'Assurance level',
      //   'Substantieel',
      // ]);
      // // Check the address card on the log entry's detailScreen.
      // final personalCardAttributes = tester.getAllText(find.descendant(
      //   of: tester.findByTypeWithContent(type: IrmaCard, content: find.text('Demo Address')),
      //   matching: find.byType(CardAttributes),
      // ));
      // expect(personalCardAttributes, [
      //   'Street',
      //   'Meander',
      //   'House number',
      //   '501',
      //   'Postal code',
      //   '1234AB',
      //   'City',
      //   'Arnhem',
      //   'Municipality',
      //   'Arnhem',
      // ]);
      // Return to the detailScreen
      await tester.tapAndSettle(find.text('Back'));
      //Return to the homeScreen
      await tester.tapAndSettle(find.byKey(const Key('irma_app_bar_leading')));
      // Wallet should contain cards
      expect(tester.any(find.text('Demo Personal data')), true);
      expect(tester.any(find.text('Demo Address')), true);
      // Tap personal data card to open
      await tester.tapAndSettle(find.text('Demo Personal data'));
      // Tap personal data card to close
      await tester.tapAndSettle(find.text('Demo Personal data'));
      // Tap Demo address card to open
      await tester.tapAndSettle(find.text('Demo Address'));
    }, timeout: const Timeout(Duration(seconds: 45)));
  });
}
