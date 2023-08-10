import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';

import 'package:irmamobile/src/screens/reset_pin/reset_pin_screen.dart';
import 'package:irmamobile/src/widgets/yivi_themed_button.dart';

import 'helpers/helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('irma-login', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('wrong-pin', (tester) async {
      // Scenario 1 of login process
      // Initialize the app for integration tests
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // Open more tab
      await tester.tapAndSettle(find.byKey(const Key('nav_button_more')));

      // Logout
      final logoutButtonFinder = find.byKey(const Key('log_out_button')).hitTestable();
      await tester.scrollUntilVisible(logoutButtonFinder, 100);
      await tester.tapAndSettle(logoutButtonFinder);

      await tester.waitFor(find.byKey(const Key('pin_screen')));

      // Login using wrong pin
      await enterPin(tester, '54321');

      // Check error dialog
      await tester.waitFor(find.byKey(const Key('irma_dialog')));

      // Check "Wrong PIN" dialog title text
      String string = tester.getAllText(find.byKey(const Key('irma_dialog_title'))).first;
      expect(string, 'PIN incorrect');

      // Check dialog text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_content'))).first;
      expect(string,
          'This PIN is not correct. You have 2 attempts left before your Yivi app will be blocked temporarily.');

      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(YiviThemedButton),
      ));

      // Press "Forgot pin"
      final forgotPinLinkFinder = find.text('I forgot my PIN').hitTestable();
      expect(forgotPinLinkFinder, findsOneWidget);
      await tester.tapAndSettle(forgotPinLinkFinder);

      // Expect to be on the reset pin screen
      final forgotPinScreenFinder = find.byType(ResetPinScreen);
      expect(forgotPinScreenFinder, findsOneWidget);

      // Expect forgotten PIN explanation content
      final actualScreenText = tester.getAllText(forgotPinScreenFinder);
      final expectedScreenText = [
        'Forgot your PIN?',
        "We're sorry but the Yivi organisation does not have a copy of your PIN. If you wish to continue using Yivi, you will have to enter a new PIN and reload all data.",
        'Cancel',
        'Start all over',
        'Forgot PIN'
      ];

      expect(actualScreenText, expectedScreenText);

      // Go back with the back button
      final backButtonFinder = find.byKey(const Key('irma_app_bar_leading'));
      await tester.tapAndSettle(backButtonFinder);

      // Now enter correct pin
      await enterPin(tester, '12345');

      // Expect to be on the home screen
      final homeScreenFinder = find.byType(HomeScreen);
      expect(homeScreenFinder, findsOneWidget);
    });

    testWidgets('blocked-pin', (tester) async {
      // Scenario 2 of login process: User is blocked after 3 failed attempts.
      // Initialize the app for integration tests
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      // Open more tab
      await tester.tapAndSettle(find.byKey(const Key('nav_button_more')));
      // Logout
      final logoutButtonFinder = find.byKey(const Key('log_out_button')).hitTestable();
      await tester.scrollUntilVisible(logoutButtonFinder, 100);
      await tester.tapAndSettle(logoutButtonFinder);
      // login using wrong pin
      await tester.waitFor(find.byKey(const Key('pin_screen')));
      await enterPin(tester, '54321');
      // Check error dialog
      await tester.waitFor(find.byKey(const Key('irma_dialog')));
      // Check "Wrong PIN" dialog title text
      String string = tester.getAllText(find.byKey(const Key('irma_dialog_title'))).first;
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_content'))).first;
      expect(string,
          'This PIN is not correct. You have 2 attempts left before your Yivi app will be blocked temporarily.');
      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(YiviThemedButton),
      ));
      // login using wrong pin
      await enterPin(tester, '54321');
      // Check error dialog
      await tester.waitFor(find.byKey(const Key('irma_dialog')));
      // Check "Wrong PIN" dialog title text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_title'))).first;
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_content'))).first;
      expect(
          string, 'This PIN is not correct. You have 1 attempt left before your Yivi app will be blocked temporarily.');
      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(YiviThemedButton),
      ));
      // login using wrong pin
      await enterPin(tester, '54321');
      // Check error dialog
      await tester.waitFor(find.byKey(const Key('irma_dialog')));
      // Check "Wrong PIN" dialog title text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_title'))).first;
      expect(string, 'App blocked');
      // Check dialog text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_content'))).first;

      expect(string, 'Your app has been blocked for 1 minute. Please try again later.');
      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(YiviThemedButton),
      ));
      // Wait 65 seconds and try again using the correct pin
      await tester.pumpAndSettle(const Duration(seconds: 65));
      await unlock(tester);
    });
  });
}
