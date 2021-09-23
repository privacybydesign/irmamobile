// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/data/irma_test_repository.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';

import 'helpers.dart';
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
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp());
      await unlock(tester);
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
      String string = tester.getAllText(find.byKey(const Key('irma_dialog_title'))).first;
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_content'))).first;
      expect(string,
          'This PIN is not correct. You have 2 attempts left before your IRMA app will be blocked temporarily.');

      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(IrmaButton),
      ));
      // Wait until wallet displayed: Successful login
      await tester.waitFor(find.byKey(const Key('wallet_present')));
    }, timeout: const Timeout(Duration(minutes: 1)));

    testWidgets('tc2', (tester) async {
      // Scenario 2 of login process: User is blocked after 3 failed attempts.
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp());
      await unlock(tester);
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
      String string = tester.getAllText(find.byKey(const Key('irma_dialog_title'))).first;
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_content'))).first;
      expect(string,
          'This PIN is not correct. You have 2 attempts left before your IRMA app will be blocked temporarily.');
      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(IrmaButton),
      ));
      // login using wrong pin
      await tester.enterTextAtFocusedAndSettle('54321');
      // Check error dialog
      await tester.waitFor(find.byKey(const Key('irma_dialog')));
      // Check "Wrong PIN" dialog title text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_title'))).first;
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_content'))).first;
      expect(
          string, 'This PIN is not correct. You have 1 attempt left before your IRMA app will be blocked temporarily.');
      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(IrmaButton),
      ));
      // login using wrong pin
      await tester.enterTextAtFocusedAndSettle('54321');
      // Check error dialog
      await tester.waitFor(find.byKey(const Key('irma_dialog')));
      // Check "Wrong PIN" dialog title text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_title'))).first;
      expect(string, 'Account blocked');
      // Check dialog text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_content'))).first;

      expect(string, 'Your account has been blocked for 1 minute. Please try again later.');
      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(IrmaButton),
      ));
      // Wait 65 seconds and try again using the correct pin
      await Future.delayed(const Duration(seconds: 65));
      // login using correct pin
      await tester.waitFor(find.byKey(const Key('pin_screen')));
      // Click pin field to open keyboard
      await tester.tapAndSettle(find.byKey(const Key('pin_field_key')));
      await tester.enterTextAtFocusedAndSettle('12345');
      // Wait until wallet displayed: Successful login
      await tester.waitFor(find.byKey(const Key('wallet_present')));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
