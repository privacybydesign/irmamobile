// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';
import 'package:flutter/foundation.dart';

import 'helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  Future<void> _initAndNavToSettingsScreen(WidgetTester tester) async {
    await pumpAndUnlockApp(tester, irmaBinding.repository);

    //Navigate to more tab
    await tester.tapAndSettle(find.byKey(const Key('nav_button_more')));

    //Open settings screen.
    await tester.tapAndSettle(find.byKey(const Key('open_settings_screen_button')));
  }

  group('settings', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('reach', (tester) async {
      await _initAndNavToSettingsScreen(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('content', (tester) async {
      await _initAndNavToSettingsScreen(tester);

      // Check screen settings text
      const String textQRscanner = 'Open QR scanner automatically after start-up';
      const String textErrorReports = 'Send error reports to Yivi';
      const String textEnableScreenshots = 'Enable screenshots';
      final list = tester.getAllText(find.byType(ListView));

      expect(list, [
        textQRscanner,
        textErrorReports,
        if (kDebugMode) ...['Developer mode'],
        if (Platform.isAndroid) ...[
          textEnableScreenshots,
          'When enabled, the app will not be blurred in the app switcher.',
        ],
        'Change your PIN',
        'Delete everything and start over',
      ]);

      // Check the initial value of all settings.
      expect(tester.getSwitchListTileValue(find.text(textQRscanner)), false);
      expect(await irmaBinding.repository.preferences.getStartQRScan().first, false);
      expect(tester.getSwitchListTileValue(find.text(textErrorReports)), false);
      expect(await irmaBinding.repository.preferences.getStartQRScan().first, false);
      // Enable all settings.
      await tester.tapAndSettle(find.text(textQRscanner));
      await tester.tapAndSettle(find.text(textErrorReports));
      // Check whether all settings are enabled.
      expect(tester.getSwitchListTileValue(find.text(textQRscanner)), true);
      expect(await irmaBinding.repository.preferences.getStartQRScan().first, true);
      expect(tester.getSwitchListTileValue(find.text(textErrorReports)), true);
      expect(await irmaBinding.repository.preferences.getStartQRScan().first, true);
      // Only on Android, check setting to enable screenshots. On iOS, the option should not be there.
      if (Platform.isAndroid) {
        expect(tester.getSwitchListTileValue(find.text(textEnableScreenshots)), true);
        expect(await irmaBinding.repository.preferences.getScreenshotsEnabled().first, true);
        await tester.tapAndSettle(find.text(textEnableScreenshots));
        expect(tester.getSwitchListTileValue(find.text(textEnableScreenshots)), false);
        expect(await irmaBinding.repository.preferences.getScreenshotsEnabled().first, false);
      } else {
        expect(find.text(textEnableScreenshots), findsNothing);
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('change-pin', (tester) async {
      await _initAndNavToSettingsScreen(tester);
      await tester.tapAndSettle(find.text('Change your PIN'));

      // Enter current pin  PIN
      await enterPin(tester, '12345');

      // Enter new PIN
      await enterPin(tester, '54321');
      await tester.tapAndSettle(find.text('Next'));

      // Enter new PIN (again)
      await enterPin(tester, '54321');

      //Press change
      await tester.tapAndSettle(find.text('Change'));

      // Expect snack bar
      var snackBarFinder = find.byType(SnackBar);
      await tester.waitFor(
        snackBarFinder,
        timeout: const Duration(seconds: 5),
      );

      expect(
        find.descendant(
          of: snackBarFinder,
          matching: find.text('The new PIN is active'),
        ),
        findsOneWidget,
      );

      // Logout
      await tester.tapAndSettle(find.byKey(const Key('irma_app_bar_leading')));
      await tester.tapAndSettle(find.byKey(const Key('nav_button_more')));
      var logoutButtonFinder = find.byKey(const Key('log_out_button'));
      await tester.scrollUntilVisible(logoutButtonFinder, 100);
      await tester.tapAndSettle(logoutButtonFinder);

      // Log back in with new pin
      await enterPin(tester, '54321');

      //Expect home screen
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('erase', (tester) async {
      await _initAndNavToSettingsScreen(tester);

      // Tap on option to delete everything and start over
      await tester.tapAndSettle(find.text('Delete everything and start over'));

      // Tap on the confirmation to delete all data
      await tester.tapAndSettle(find.text('Yes, delete everything'));

      // Check whether the enrollment screen is shown
      await tester.waitFor(find.byType(EnrollmentScreen));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
