// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/data/irma_test_repository.dart';

import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('irma-screens', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    IrmaTestRepository testRepo;
    setUpAll(() async => testRepo = await IrmaTestRepository.ensureInitialized());
    setUp(() => testRepo.init());
    tearDown(() => testRepo.clean());

    testWidgets('tc1', (tester) async {
      await tester.pumpWidgetAndSettle(IrmaApp());

      // Check first screen
      print("Check intro heading");
      String string = tester.getText(find.byKey(const Key('intro_heading')), firstMatchOnly: true);
      expect(string, 'IRMA is your identity on your mobile');
      print("Check intro text");
      string = tester.getText(find.byKey(const Key('intro_body')), firstMatchOnly: true);
      expect(string, 'Your official name, date of birth, address, and more. All securely stored in your IRMA app.');

      // Tap through enrollment info screens
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p1')), matching: find.byKey(const Key('next'))));

      // Check second screen
      print("Check intro heading");
      string = tester.getText(find.byKey(const Key('intro_heading')), firstMatchOnly: true);
      expect(string, 'Make yourself known with IRMA');
      print("Check intro text");
      string = tester.getText(find.byKey(const Key('intro_body')), firstMatchOnly: true);
      expect(string, "Easy, secure, and fast. It's all in your hands.");

      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p2')), matching: find.byKey(const Key('next'))));

      // Check third screen
      print("Check intro heading");
      string = tester.getText(find.byKey(const Key('intro_heading')), firstMatchOnly: true);
      expect(string, 'IRMA provides certainty, to you and to others');
      print("Check intro text");
      string = tester.getText(find.byKey(const Key('intro_body')), firstMatchOnly: true);
      expect(string, "Your data are stored solely within the IRMA app. Only you have access.");
      string = tester.getText(find.byKey(const Key('intro_body_link')), firstMatchOnly: true);

      expect(string, "Please read the privacy rules");

      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p3')), matching: find.byKey(const Key('next'))));

      // Choose new pin screen
      expect(tester.any(find.byKey(const Key('enrollment_choose_pin'))), true);
    }, timeout: const Timeout(Duration(minutes: 4)));

    testWidgets('tc2', (tester) async {
      // Scenario 2 of IRMA app screens
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp());
      // Tap through enrollment info screens
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p1')), matching: find.byKey(const Key('next'))));
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p2')), matching: find.byKey(const Key('next'))));
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p3')), matching: find.byKey(const Key('next'))));
      // Enter pin
      await tester.enterTextAtFocusedAndSettle('12345');
      // Confirm pin
      await tester.enterTextAtFocusedAndSettle('12345');
      // Skip email providing
      await tester.tapAndSettle(find.byKey(const Key('enrollment_skip_email')));
      await tester.tap(find.byKey(const Key('enrollment_skip_confirm')));
      // Wait until wallet displayed
      await tester.waitFor(find.byKey(const Key('wallet_present')));
      // Open menu
      await tester.tapAndSettle(find.byKey(const Key('open_menu_icon')));
      // Logout
      await tester.tapAndSettle(find.byKey(const Key('menu_logout')));
      // login window is displayed
      // Check screen title
      String string = tester.getText(find.byKey(const Key('pinscreen_app_bar')), firstMatchOnly: true);
      expect(string, 'Login');

      string = tester.getText(find.byKey(const Key('pin_screen')), firstMatchOnly: true);
      expect(string, 'Enter your PIN');
      await tester.waitFor(find.byKey(const Key('pin_field_key')));
      string = tester.getText(find.byKey(const Key('irma_link')), firstMatchOnly: true);
      expect(string, 'PIN forgotten');

      await tester.tapAndSettle(find.byKey(const Key('irma_link')));

      string = tester.getText(find.byKey(const Key('reset_pin_screen')), firstMatchOnly: true);

      String screenText =
          '''Lost your PIN? We\'re sorry but the IRMA organisation does not keep record of your PIN. If you wish to continue using IRMA, you will have to enter a new PIN and reload all data.''';

      expect(string, screenText);

      // Check buttons Back and Reset
      await tester.waitFor(
          find.descendant(of: find.byKey(const Key('reset_pin_buttons')), matching: find.byKey(const Key('primary'))));
      await tester.waitFor(find.descendant(
          of: find.byKey(const Key('reset_pin_buttons')), matching: find.byKey(const Key('secondary'))));
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('tc3', (tester) async {
      // Scenario 3 of IRMA app screens
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp());
      // Tap through enrollment info screens
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p1')), matching: find.byKey(const Key('next'))));
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p2')), matching: find.byKey(const Key('next'))));
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p3')), matching: find.byKey(const Key('next'))));
      // Enter pin
      await tester.enterTextAtFocusedAndSettle('12345');
      // Confirm pin
      await tester.enterTextAtFocusedAndSettle('12345');
      // Skip email providing
      await tester.tapAndSettle(find.byKey(const Key('enrollment_skip_email')));
      await tester.tap(find.byKey(const Key('enrollment_skip_confirm')));
      // Wait until wallet displayed
      await tester.waitFor(find.byKey(const Key('wallet_present')));
      // Check wallet text
      String string = tester.getText(find.byKey(const Key('wallet_screen')), firstMatchOnly: true);
      expect(string, 'Your data securely on your mobile');
      // Check button Add more data
      expect(tester.any(find.byKey(const Key('add_cards_button'))), true);

      // Wallet should not contain any cards
      expect(tester.any(find.byKey(const Key('wallet_card_0'))), false);
    }, timeout: const Timeout(Duration(minutes: 4)));

    testWidgets('tc4', (tester) async {
      // Scenario 4 of IRMA app screens: Help screen
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp());
      // Tap through enrollment info screens
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p1')), matching: find.byKey(const Key('next'))));
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p2')), matching: find.byKey(const Key('next'))));
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p3')), matching: find.byKey(const Key('next'))));
      // Enter pin
      await tester.enterTextAtFocusedAndSettle('12345');
      // Confirm pin
      await tester.enterTextAtFocusedAndSettle('12345');
      // Skip email providing
      await tester.tapAndSettle(find.byKey(const Key('enrollment_skip_email')));
      await tester.tap(find.byKey(const Key('enrollment_skip_confirm')));
      // Wait until wallet displayed
      await tester.waitFor(find.byKey(const Key('wallet_present')));

      await tester.tapAndSettle(find.byKey(const Key('wallet_button_help')));

      // Check screen title
      String string = tester.getText(find.byKey(const Key('irma_app_bar')), firstMatchOnly: true);
      expect(string, 'Help');
      // Check screen header
      string = tester.getText(find.byKey(const Key('help_screen_heading')), firstMatchOnly: true);
      expect(string, 'Manual');
      // Check box content
      string = tester.getText(find.byKey(const Key('help_screen_content')), firstMatchOnly: true);
      expect(string, 'How to use IRMA? See the explanations below.');
      // Check button "Back to IRMA cards"
      await tester.waitFor(find.byKey(const Key('back_to_wallet_button')));
    }, timeout: const Timeout(Duration(minutes: 4)));
  });
}
