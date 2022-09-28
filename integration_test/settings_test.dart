// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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

    Future<void> _testToggle(WidgetTester tester, String key, bool defaultValue, Stream<bool> valueStream) async {
      var toggleFinder = find.byKey(Key(key));
      await tester.scrollUntilVisible(toggleFinder, 50);

      // Find the actual SwitchListTile in the SettingsSwitchListTile
      var switchTileFinder = find.descendant(
        of: toggleFinder,
        matching: find.byType(SwitchListTile),
      );

      // Check default value
      expect(
        (switchTileFinder.evaluate().single.widget as SwitchListTile).value,
        defaultValue,
      );

      // Toggle it
      await tester.tapAndSettle(toggleFinder);

      // Check switch tile is toggled
      expect(
        (switchTileFinder.evaluate().single.widget as SwitchListTile).value,
        !defaultValue,
      );

      // Check if value in repo is toggled
      expect(
        await valueStream.first,
        !defaultValue,
      );
    }

    testWidgets('reach', (tester) async {
      await _initAndNavToSettingsScreen(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets(
      'toggles',
      (tester) async {
        final repo = irmaBinding.repository;
        await _initAndNavToSettingsScreen(tester);

        await _testToggle(
          tester,
          'qr_toggle',
          false,
          repo.preferences.getStartQRScan(),
        );
        await _testToggle(
          tester,
          'report_toggle',
          false,
          repo.preferences.getReportErrors(),
        );
        if (kDebugMode) {
          await _testToggle(
            tester,
            'dev_mode_toggle',
            true,
            repo.getDeveloperMode(),
          );
        }
        if (Platform.isAndroid) {
          await _testToggle(
            tester,
            'screenshot_toggle',
            true,
            repo.preferences.getScreenshotsEnabled(),
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    // testWidgets('change-pin', (tester) async {
    //   await _initAndNavToSettingsScreen(tester);
    //   await tester.tapAndSettle(find.text('Change your PIN'));

    //   // Enter current pin  PIN
    //   await enterPin(tester, '12345');

    //   // Enter new PIN
    //   await enterPin(tester, '54321');

    //   //Next button
    //   var nextButtonFinder = find.byKey(
    //     const Key('pin_next'),
    //   );
    //   await tester.ensureVisible(nextButtonFinder);
    //   await tester.tapAndSettle(nextButtonFinder);

    //   // Enter new PIN (again)
    //   await enterPin(tester, '54321');

    //   //Press change
    //   await tester.tapAndSettle(find.text('Change'));

    //   // Expect snack bar
    //   var snackBarFinder = find.byType(SnackBar);
    //   await tester.waitFor(
    //     snackBarFinder,
    //     timeout: const Duration(seconds: 5),
    //   );

    //   expect(
    //     find.descendant(
    //       of: snackBarFinder,
    //       matching: find.text('The new PIN is active'),
    //     ),
    //     findsOneWidget,
    //   );

    //   // Logout
    //   await tester.tapAndSettle(find.byKey(const Key('irma_app_bar_leading')));
    //   await tester.tapAndSettle(find.byKey(const Key('nav_button_more')));
    //   var logoutButtonFinder = find.byKey(const Key('log_out_button'));
    //   await tester.scrollUntilVisible(logoutButtonFinder, 100);
    //   await tester.tapAndSettle(logoutButtonFinder);

    //   // Log back in with new pin
    //   await enterPin(tester, '54321');

    //   //Expect home screen
    //   expect(find.byType(HomeScreen), findsOneWidget);
    // });

    testWidgets('erase', (tester) async {
      await _initAndNavToSettingsScreen(tester);

      var deleteFinder = find.text('Delete everything and start over');

      // Tap on option to delete everything and start over
      await tester.scrollUntilVisible(deleteFinder, 75);
      await tester.tapAndSettle(deleteFinder);

      // Tap on the confirmation to delete all data
      await tester.tapAndSettle(find.text('Yes, delete everything'));

      // Check whether the enrollment screen is shown
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
