import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/data/irma_test_repository.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';

import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('irma-login', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    IrmaTestRepository testRepo;
    setUpAll(() async => testRepo = await IrmaTestRepository.ensureInitialized());
    setUp(() => testRepo.init());
    tearDown(() => testRepo.clean());

    testWidgets('tc1', (tester) async {
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

    testWidgets('tc2', (tester) async {
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
  });
}
