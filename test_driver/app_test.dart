import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';

import 'app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('IrmaMobile', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUpAll(setUpRepository);
    tearDown(cleanRepository);

    testWidgets('irma-screens-tc1', (tester) async {
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
      // Check Next button is available
      //await driver
      //    .waitFor(find.descendant(of: find.byKey(const Key('enrollment_p2')), matching: find.byKey(const Key('next'))));
      print("Check intro heading");
      string = tester.getText(find.byKey(const Key('intro_heading')), firstMatchOnly: true);
      expect(string, 'Make yourself known with IRMA');
      print("Check intro text");
      string = tester.getText(find.byKey(const Key('intro_body')), firstMatchOnly: true);
      expect(string, "Easy, secure, and fast. It's all in your hands.");

      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p2')), matching: find.byKey(const Key('next'))));

      // Check third screen
      // Check Next button is available
      //await driver
      //    .waitFor(find.descendant(of: find.byKey(const Key('enrollment_p3')), matching: find.byKey(const Key('next'))));
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

    testWidgets('irma-screens-tc2', (tester) async {
      // Scenario 2 of IRMA app screens
      //await tester.waitFor(find.byKey(const Key('enrollment_p1')));
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
      //await tester.waitFor(find.byKey(const Key('enrollment_choose_pin')));
      await tester.enterTextAtFocusedAndSettle('12345');
      // Confirm pin
      //await tester.waitFor(find.byKey(const Key('enrollment_confirm_pin')));
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
      //await tester.waitFor(find.byKey(const Key('pin_screen')));
      // Check screen title
      String string = tester.getText(find.byKey(const Key('pinscreen_app_bar')), firstMatchOnly: true);
      expect(string, 'Login');

      string = tester.getText(find.byKey(const Key('pin_screen')), firstMatchOnly: true);
      expect(string, 'Enter your PIN');
      await tester.waitFor(find.byKey(const Key('pin_field_key')));
      string = tester.getText(find.byKey(const Key('irma_link')), firstMatchOnly: true);
      expect(string, 'PIN forgotten');

      await tester.tapAndSettle(find.byKey(const Key('irma_link')));

      //await tester.waitFor(find.byKey(const Key('reset_pin_screen')));

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

    testWidgets('irma-screens-tc4', (tester) async {
      // Scenario 4 of IRMA app screens
      //await tester.waitFor(find.byKey(const Key('enrollment_p1')));
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
      //await tester.waitFor(find.byKey(const Key('enrollment_choose_pin')));
      await tester.enterTextAtFocusedAndSettle('12345');
      // Confirm pin
      //await tester.waitFor(find.byKey(const Key('enrollment_confirm_pin')));
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

    testWidgets('irma-screens-tc5', (tester) async {
      // Scenario 5 of IRMA app screens: Help screen
      //await tester.waitFor(find.byKey(const Key('enrollment_p1')));
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
      //await tester.waitFor(find.byKey(const Key('enrollment_choose_pin')));
      await tester.enterTextAtFocusedAndSettle('12345');
      // Confirm pin
      //await tester.waitFor(find.byKey(const Key('enrollment_confirm_pin')));
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

    testWidgets('irma-login-tc1', (tester) async {
      // Scenario 1 of login process
      //await tester.waitFor(find.byKey(const Key('enrollment_p1')));
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
      //await tester.waitFor(find.byKey(const Key('enrollment_choose_pin')));
      await tester.enterTextAtFocusedAndSettle('12345');
      // Confirm pin
      //await tester.waitFor(find.byKey(const Key('enrollment_confirm_pin')));
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
      // login using wrong pin
      await tester.waitFor(find.byKey(const Key('pin_screen')));
      await tester.enterTextAtFocusedAndSettle('54321');
      // Check error dialog
      await tester.waitFor(find.byKey(const Key('irma_dialog')));
      // Check "Wrong PIN" dialog title text
      print('check dialog title');
      String string = tester.getText(find.byKey(const Key('irma_dialog_title')));
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = tester.getText(find.byKey(const Key('irma_dialog_content')));
      expect(string,
          'This PIN is not correct. You have 2 attempts left before your IRMA app will be blocked temporarily.');

      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(IrmaButton),
      ));
      // Wait until wallet displayed: Successful login
      await tester.waitFor(find.byKey(const Key('wallet_present')));
    }, timeout: const Timeout(Duration(minutes: 4)));

    testWidgets('irma-login-tc2', (tester) async {
      // Scenario 2 of login process: User is blocked after 3 failed attempts.
      //await tester.waitFor(find.byKey(const Key('enrollment_p1')));
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
      await tester.tapAndSettle(find.byKey(const Key('pin_field_key')));
      //await tester.waitFor(find.byKey(const Key('enrollment_choose_pin')));
      await tester.enterTextAtFocusedAndSettle('12345');
      // Confirm pin
      //await tester.waitFor(find.byKey(const Key('enrollment_confirm_pin')));
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
      // login using wrong pin
      await tester.waitFor(find.byKey(const Key('pin_screen')));
      await tester.enterTextAtFocusedAndSettle('54321');
      // Check error dialog
      await tester.waitFor(find.byKey(const Key('irma_dialog')));
      // Check "Wrong PIN" dialog title text
      String string = tester.getText(find.byKey(const Key('irma_dialog_title')));
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = tester.getText(find.byKey(const Key('irma_dialog_content')));
      expect(string,
          'This PIN is not correct. You have 2 attempts left before your IRMA app will be blocked temporarily.');
      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(IrmaButton),
      ));
      // login using wrong pin
      //await tester.waitFor(find.byKey(const Key('pin_screen')));
      await tester.enterTextAtFocusedAndSettle('54321');
      // Check error dialog
      await tester.waitFor(find.byKey(const Key('irma_dialog')));
      // Check "Wrong PIN" dialog title text
      string = tester.getText(find.byKey(const Key('irma_dialog_title')));
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = tester.getText(find.byKey(const Key('irma_dialog_content')));
      expect(
          string, 'This PIN is not correct. You have 1 attempt left before your IRMA app will be blocked temporarily.');
      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(IrmaButton),
      ));
      // login using wrong pin
      //await tester.waitFor(find.byKey(const Key('pin_screen')));
      await tester.enterTextAtFocusedAndSettle('54321');
      // Check error dialog
      await tester.waitFor(find.byKey(const Key('irma_dialog')));
      // Check "Wrong PIN" dialog title text
      string = tester.getText(find.byKey(const Key('irma_dialog_title')));
      expect(string, 'Account blocked');
      // Check dialog text
      string = tester.getText(find.byKey(const Key('irma_dialog_content')));

      expect(string, 'Your account has been blocked for 1 minute. Please try again later.');
      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(IrmaButton),
      ));
      // Wait 65 seconds and try again using the correct pin
      print('Wait 65 seconds for account to get unlocked...');
      await Future.delayed(const Duration(seconds: 65));
      // login using correct pin
      await tester.waitFor(find.byKey(const Key('pin_screen')));
      // Click pin field to open keyboard
      await tester.tapAndSettle(find.byKey(const Key('pin_field_key')));
      await tester.enterTextAtFocusedAndSettle('54321');
      // Wait until wallet displayed: Successful login
      await tester.waitFor(find.byKey(const Key('wallet_present')));
    }, timeout: const Timeout(Duration(minutes: 10)));

    testWidgets('irma-enroll-tc1', (tester) async {
      // Scenario 1 of enrollment process
      // Wait for initialization
      //await tester.waitFor(find.byKey(const Key('enrollment_p1')));
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp());

      // Tap through enrollment info screens
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p1')), matching: find.byKey(const Key('next'))));
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p2')), matching: find.byKey(const Key('next'))));
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p3')), matching: find.byKey(const Key('next'))));

      // Choose new pin screen
      //await tester.waitFor(find.byKey(const Key('enrollment_choose_pin')));
      // Enter Pin
      await tester.enterTextAtFocusedAndSettle('12345');
      // Enter wrong pin
      //await tester.waitFor(find.byKey(const Key('enrollment_confirm_pin')));
      await tester.enterTextAtFocusedAndSettle('67890');

      await tester.waitFor(find.byKey(const Key('irma_dialog')));

      // Check "Wrong PIN" dialog title text
      String string = tester.getText(find.byKey(const Key('irma_dialog_title')));
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = tester.getText(find.byKey(const Key('irma_dialog_content')));
      expect(string, 'PINs do not match. Choose a new PIN.');

      await tester
          .tapAndSettle(find.descendant(of: find.byKey(const Key('irma_dialog')), matching: find.byType(IrmaButton)));

      // Choose new pin screen
      //await tester.waitFor(find.byKey(const Key('enrollment_choose_pin')));
      // Enter Pin
      await tester.enterTextAtFocusedAndSettle('12345');
      // Enter wrong pin
      //await tester.waitFor(find.byKey(const Key('enrollment_confirm_pin')));
      await tester.enterTextAtFocusedAndSettle('12345');

      // Enter email address
      //await tester.waitFor(find.byKey(const Key('enrollment_provide_email')));

      // Check error message is not displayed
      expect(
        tester.any(find.descendant(
            of: find.byKey(const Key('enrollment_provide_email_textfield')),
            matching: find.text('This is not a valid email address'))),
        false,
      );

      await tester.enterTextAtFocusedAndSettle('Wrong_syntax');
      await tester.tapAndSettle(find.byKey(const Key('enrollment_email_next')));

      // Check error message
      expect(
        tester.any(find.descendant(
            of: find.byKey(const Key('enrollment_provide_email_textfield')),
            matching: find.text('This is not a valid email address'))),
        true,
      );

      // Check textfield is still present
      expect(
        tester.any(
            find.descendant(of: find.byKey(const Key('enrollment_provide_email')), matching: find.byType(TextField))),
        true,
      );

      await tester.enterTextAtFocusedAndSettle('testing_irma_app@example.com');
      await tester.tapAndSettle(find.byKey(const Key('enrollment_email_next')));

      // Wait for Email confirmation screen
      await tester.waitFor(find.byKey(const Key('email_sent_screen')));
      print('check screen title');
      // Check screen title
      string = tester.getText(find.byKey(const Key('irma_app_bar')), firstMatchOnly: true);
      expect(string, 'Secure your IRMA app');

      // Check text
      string = tester.getText(
        find.descendant(of: find.byKey(const Key('email_sent_screen')), matching: find.byType(Text)),
        firstMatchOnly: true,
      );
      expect(string, 'Confirm your email address');

      // Click continue
      await tester.tapAndSettle(find.descendant(
          of: find.byKey(const Key('email_sent_screen_continue')), matching: find.byKey(const Key('primary'))));

      // Wait until wallet displayed
      await tester.waitFor(find.byKey(const Key('wallet_present')));
      // No cards should be available in the wallet
      expect(tester.any(find.byKey(const Key('wallet_card_0'))), false);
    }, timeout: const Timeout(Duration(minutes: 4)));

    testWidgets('irma-enroll-tc2', (tester) async {
      // Scenario 2 of enrollment process
      // Wait for initialization
      //await tester.waitFor(find.byKey(const Key('enrollment_p1')));

      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp());

      // Tap through enrollment info screens
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p1')), matching: find.byKey(const Key('next'))));
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p2')), matching: find.byKey(const Key('next'))));
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('enrollment_p3')), matching: find.byKey(const Key('next'))));

      // Choose new pin screen
      //await tester.waitFor(find.byKey(const Key('enrollment_choose_pin')));

      // Check screen title
      String string = tester.getText(find.byKey(const Key('irma_app_bar')), firstMatchOnly: true);
      expect(string, 'Secure your IRMA app');

      // Check text
      string = tester.getText(
        find.descendant(of: find.byKey(const Key('enrollment_choose_pin')), matching: find.byType(Text)),
        firstMatchOnly: true,
      );
      expect(string, 'Choose a 5-digit PIN');

      // Enter Pin
      print('Enter pin');
      await tester.enterTextAtFocusedAndSettle('12345');

      // Confirm pin
      //await tester.waitFor(find.byKey(const Key('enrollment_confirm_pin')));

      // Check screen title
      print('check screen title Secure your irma app');
      string = tester.getText(find.byKey(const Key('irma_app_bar')), firstMatchOnly: true);
      expect(string, 'Secure your IRMA app');

      // Check text
      print('check text Enter your pin');
      string = tester.getText(find.byKey(const Key('enrollment_confirm_pin')), firstMatchOnly: true);
      expect(string, 'Enter your PIN again');

      await tester.enterTextAtFocusedAndSettle('12345');

      // Wait for screen to provide email address
      //await tester.waitFor(find.byKey(const Key('enrollment_provide_email')));

      // Check screen title
      print('check screen title Secure your irma app');
      string = tester.getText(find.byKey(const Key('irma_app_bar')), firstMatchOnly: true);
      expect(string, 'Secure your IRMA app');

      // Check text
      print('check text email enrollment');
      string = tester.getText(find.byKey(const Key('enrollment_provide_email')), firstMatchOnly: true);
      expect(string, 'An email address allows you to disable your IRMA app when your mobile has been lost or stolen.');

      // Check textfield
      print('check textfield email');
      expect(
        tester.any(
            find.descendant(of: find.byKey(const Key('enrollment_provide_email')), matching: find.byType(TextField))),
        true,
      );

      // Check buttons Skip & Next
      print('check buttons Skip & Next');
      expect(tester.any(find.byKey(const Key('enrollment_skip_email'))), true);
      expect(tester.any(find.byKey(const Key('enrollment_email_next'))), true);

      // Click Skip
      print('Skip Email');
      await tester.tapAndSettle(find.byKey(const Key('enrollment_skip_email')));
      print('check irma dialog is displayed');
      await tester.waitFor(find.byKey(const Key('irma_dialog')));
      // Check dialog title text
      string = tester.getText(find.byKey(const Key('irma_dialog_title')));
      expect(string, 'Are you sure?');
      // Check dialog text
      string = tester.getText(find.byKey(const Key('irma_dialog_content')));
      expect(string,
          'Protect your data. When you enter an email address, you can block your IRMA app when your mobile has been lost or stolen.');

      // Confirm Skip
      await tester.tap(find.byKey(const Key('enrollment_skip_confirm')));

      // Wait until wallet displayed
      await tester.waitFor(find.byKey(const Key('wallet_present')));
      // No cards should be available in the wallet
      expect(tester.any(find.byKey(const Key('wallet_card_0'))), false);
    }, timeout: const Timeout(Duration(minutes: 4)));

    testWidgets('irma-issuance-tc1', (tester) async {
      // Scenario 1 of issuance process
      //await tester.waitFor(find.byKey(const Key('enrollment_p1')));
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
      //await tester.waitFor(find.byKey(const Key('enrollment_choose_pin')));
      await tester.enterTextAtFocusedAndSettle('12345');
      // Confirm pin
      //await tester.waitFor(find.byKey(const Key('enrollment_confirm_pin')));
      await tester.enterTextAtFocusedAndSettle('12345');
      // Skip email providing
      await tester.tapAndSettle(find.byKey(const Key('enrollment_skip_email')));
      await tester.tap(find.byKey(const Key('enrollment_skip_confirm')));
      // Wait until wallet displayed
      await tester.waitFor(find.byKey(const Key('wallet_present')));

      // Start session
      await IrmaRepository.get().startTestSession("""
      {
        "@context": "https://irma.app/ld/request/issuance/v2",
        "credentials": [
          {
            "credential": "irma-demo.gemeente.personalData",
            "attributes": {
              "initials": "W.L.",
              "firstnames": "Willeke Liselotte",
              "prefix": "de",
              "familyname": "Bruijn",
              "fullname": "W.L. de Bruijn",
              "gender": "V",
              "nationality": "Ja",
              "surname": "de Bruijn",
              "dateofbirth": "10-04-1965",
              "cityofbirth": "Amsterdam",
              "countryofbirth": "Nederland",
              "over12": "Yes",
              "over16": "Yes",
              "over18": "Yes",
              "over21": "Yes",
              "over65": "No",
              "bsn": "999999990",
              "digidlevel": "Substantieel"
            }
          },
          {
            "credential": "irma-demo.gemeente.address",
            "attributes": {
              "street":"Meander","houseNumber":"501","zipcode":"1234AB","municipality":"Arnhem","city":"Arnhem"
            }
          }
        ]
      }
      """);
      // Accept issued credential
      await tester.waitFor(find.byKey(const Key('issuance_accept')));
      await tester.tap(
          find.descendant(of: find.byKey(const Key('issuance_accept')), matching: find.byKey(const Key('primary'))));
      // Wait until done
      await tester.waitFor(find.byKey(const Key('wallet_present')));

      // Check whether the cards are present in the wallet
      expect(tester.any(find.byKey(const Key('wallet_card_0'))), true);
      expect(tester.any(find.byKey(const Key('wallet_card_1'))), true);
      print('wait 5 seconds');
      await tester.pumpAndSettle(const Duration(seconds: 5));
      print('Tap personal data card to open');
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('wallet_card_0')), matching: find.byKey(const Key('card_title'))));

      print('Checking Personal data card');
      String string = tester.getText(
          find.descendant(of: find.byKey(const Key('wallet_card_0')), matching: find.byKey(const Key('card_title'))));

      expect(string, 'Demo Personal data');

      print('Checking Names and values');

      print('checking initials');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_0_name', 'Initials');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_0_value', 'W.L.');

      print('checking First names');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_1_name', 'First names');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_1_value', 'Willeke Liselotte');

      print('checking Prefix');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_2_name', 'Prefix');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_2_value', 'de');

      print('checking Family name');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_3_name', 'Family name');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_3_value', 'Bruijn');

      print('checking Full name');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_4_name', 'Full name');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_4_value', 'W.L. de Bruijn');

      print('checking Gender');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_5_name', 'Gender');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_5_value', 'V');

      print('checking nationality');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_6_name', 'Dutch nationality');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_6_value', 'Ja');

      print('checking Surname');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_7_name', 'Surname');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_7_value', 'de Bruijn');

      print('checking Date of birth');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_8_name', 'Date of birth');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_8_value', '10-04-1965');

      print('checking City of birth');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_9_name', 'City of birth');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_9_value', 'Amsterdam');

      print('checking Country of birth');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_10_name', 'Country of birth');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_10_value', 'Nederland');

      print('checking Age');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_11_name', 'Over 12');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_11_value', 'Yes');

      await tester.scrollAndCheckText('wallet_card_0', 'attr_12_name', 'Over 16');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_12_value', 'Yes');

      await tester.scrollAndCheckText('wallet_card_0', 'attr_13_name', 'Over 18');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_13_value', 'Yes');

      await tester.scrollAndCheckText('wallet_card_0', 'attr_14_name', 'Over 21');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_14_value', 'Yes');

      await tester.scrollAndCheckText('wallet_card_0', 'attr_15_name', 'Over 65');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_15_value', 'No');

      print('Checking BSN');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_16_name', 'BSN');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_16_value', '999999990');

      print('checking DigiD assurance level');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_17_name', 'DigiD assurance level');
      await tester.scrollAndCheckText('wallet_card_0', 'attr_17_value', 'Substantieel');

      print('Tap personal data card to close');
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('wallet_card_0')), matching: find.byKey(const Key('card_title'))));

      print('Tap Demo address card to open');
      await tester.tapAndSettle(
          find.descendant(of: find.byKey(const Key('wallet_card_1')), matching: find.byKey(const Key('card_title'))));

      print('Checking Demo address card');

      string = tester.getText(
          find.descendant(of: find.byKey(const Key('wallet_card_1')), matching: find.byKey(const Key('card_title'))));
      expect(string, 'Demo Address');
      print('Checking Gemeente adresgegevens - Names and values');

      print('Checking Address');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_0_name', 'Street');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_0_value', 'Meander');

      print('Checking Huisnummer');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_1_name', 'House number');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_1_value', '501');

      print('Checking Postcode');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_2_name', 'Zip code');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_2_value', '1234AB');

      print('Checking Gemeente');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_3_name', 'Municipality');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_3_value', 'Arnhem');

      print('Checking City');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_4_name', 'City');
      await tester.scrollAndCheckText('wallet_card_1', 'attr_4_value', 'Arnhem');
    }, timeout: const Timeout(Duration(minutes: 4)));
  });
}

// TODO: Move this extension into lib/src
extension WidgetTesterUtil on WidgetTester {
  /// Renders the given widget and waits until it settles.
  Future<void> pumpWidgetAndSettle(Widget w) async {
    await pumpWidget(w);
    await pumpAndSettle();
  }

  // TODO: Find element that currently has focus to test autofocus
  /// Enters the given text in the EditableText that currently is in focus.
  Future<void> enterTextAtFocusedAndSettle(String text) async {
    await enterText(find.byType(EditableText), text);
    await pumpAndSettle(const Duration(milliseconds: 500));
  }

  /// Taps on the element the given widget, waits for a response, triggers a new frame sequence
  /// to be rendered (check the description of pump) and waits until the widget settles.
  /// The waiting time can be specified using 'duration'.
  Future<void> tapAndSettle(Finder f, {Duration duration = const Duration(milliseconds: 100)}) async {
    await tap(f);
    await pumpAndSettle(duration);
  }

  /// Waits for the given widget to appear. When the timeout passes, an exception is given.
  Future<void> waitFor(Finder f, {Duration timeout = const Duration(minutes: 1)}) => Future.doWhile(() async {
        await pumpAndSettle();
        return !any(f);
      }).timeout(timeout);

  /// Returns the string being inside the given Text widget.
  /// When 'firstMatchOnly' is true, it also checks descendants of the given widget for text being present.
  /// Only the first match is returned.
  String getText(Finder f, {bool firstMatchOnly = false}) => firstMatchOnly
      ? firstWidget<Text>(find.descendant(of: f, matching: find.byType(Text), matchRoot: true)).data
      : widget<Text>(f).data;

  /// Looks for a Scrollable inside a widget with Key 'parentKey', scrolls through all items
  /// to look for a Text widget with Key 'textKey' and checks whether its value equals to 'textValue'.
  Future<void> scrollAndCheckText(String parentKey, String textKey, String textValue) async {
    final parentWidget = find.byKey(Key(parentKey));
    final textWidget = find.descendant(of: parentWidget, matching: find.byKey(Key(textKey)));
    await scrollUntilVisible(textWidget, 30,
        scrollable: find.descendant(
          of: parentWidget,
          matching: find.byWidgetPredicate((widget) => widget is Scrollable),
          matchRoot: true,
        ));
    final string = getText(textWidget);
    expect(string, textValue);
  }
}
