// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/main.dart';

import 'helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('irma-screens', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('tc1', (tester) async {
      // Scenario 1 of IRMA app screens
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(const IrmaApp());
      await unlock(tester);
      // Open menu
      await tester.tapAndSettle(find.byKey(const Key('open_menu_icon')));
      // Logout
      await tester.tapAndSettle(find.byKey(const Key('menu_logout')));
      // login window is displayed
      // Check screen title
      String string = tester.getAllText(find.byKey(const Key('pinscreen_app_bar'))).first;
      expect(string, 'Login');

      string = tester.getAllText(find.byKey(const Key('pin_screen'))).first;
      expect(string, 'Enter your PIN');
      await tester.waitFor(find.byKey(const Key('pin_field_key')));
      string = tester.getAllText(find.byKey(const Key('irma_link'))).first;
      expect(string, 'PIN forgotten');

      await tester.tapAndSettle(find.byKey(const Key('irma_link')));

      string = tester.getAllText(find.byKey(const Key('reset_pin_screen'))).first;

      String screenText =
          "Lost your PIN? We're sorry but the IRMA organisation does not keep record of your PIN. If you wish to continue using IRMA, you will have to enter a new PIN and reload all data.";

      expect(string, screenText);

      // Check buttons Back and Reset
      await tester.waitFor(
          find.descendant(of: find.byKey(const Key('reset_pin_buttons')), matching: find.byKey(const Key('primary'))));
      await tester.waitFor(find.descendant(
          of: find.byKey(const Key('reset_pin_buttons')), matching: find.byKey(const Key('secondary'))));
    }, timeout: const Timeout(Duration(minutes: 1)));

    testWidgets('tc2', (tester) async {
      // Scenario 2 of IRMA app screens
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(const IrmaApp());
      await unlock(tester);
      // Check wallet text
      String string = tester.getAllText(find.byKey(const Key('wallet_screen'))).first;
      expect(string, 'Your data securely on your mobile');
      // Check button Add more data
      expect(tester.any(find.byKey(const Key('add_cards_button'))), true);

      // Wallet should not contain any cards
      expect(tester.any(find.byKey(const Key('wallet_card_0'))), false);
    }, timeout: const Timeout(Duration(minutes: 1)));

    testWidgets('tc3', (tester) async {
      // Scenario 3 of IRMA app screens: Help screen
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(const IrmaApp());
      await unlock(tester);

      await tester.tapAndSettle(find.byKey(const Key('wallet_button_help')));

      // Check screen title
      String string = tester.getAllText(find.byKey(const Key('irma_app_bar'))).first;
      expect(string, 'Help');
      // Check screen header
      string = tester.getAllText(find.byKey(const Key('help_screen_heading'))).first;
      expect(string, 'Manual');
      // Check box content
      string = tester.getAllText(find.byKey(const Key('help_screen_content'))).first;
      expect(string, 'How to use IRMA? See the explanations below.');
      // Check button "Back to IRMA cards"
      await tester.waitFor(find.byKey(const Key('back_to_wallet_button')));
    }, timeout: const Timeout(Duration(minutes: 1)));
  });
}
