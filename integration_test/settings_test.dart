import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:irmamobile/app.dart';
import 'package:irmamobile/src/screens/change_language/change_language_screen.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

import 'helpers/helpers.dart';
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

    Future<void> _testToggle(
      WidgetTester tester,
      String key,
      bool defaultValue,
      Stream<bool> valueStream,
    ) async {
      var toggleFinder = find.byKey(Key(key));
      await tester.scrollUntilVisible(toggleFinder.hitTestable(), 50);

      // Find the actual Switch in the ToggleTile
      var switchFinder = find.descendant(
        of: toggleFinder,
        matching: find.byType(CupertinoSwitch),
      );

      // Check default value
      expect(
        (switchFinder.evaluate().single.widget as CupertinoSwitch).value,
        defaultValue,
      );

      // Toggle it
      await tester.tapAndSettle(toggleFinder);

      // Check switch tile is toggled
      expect(
        (switchFinder.evaluate().single.widget as CupertinoSwitch).value,
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

        // ! Note: there is no test to toggle the scanner on startup
        // ! because it will ask for camera permissions

        await _testToggle(
          tester,
          'report_toggle',
          false,
          repo.preferences.getReportErrors(),
        );
        if (Platform.isAndroid) {
          await _testToggle(
            tester,
            'screenshot_toggle',
            true,
            repo.preferences.getScreenshotsEnabled(),
          );
        }

        // Dev mode is enabled by default in the test binding
        // so the toggle should be visible.
        await _testToggle(
          tester,
          'dev_mode_toggle',
          true,
          repo.getDeveloperMode(),
        );

        // Now go back and return to settings again
        await tester.tapAndSettle(find.byKey(const Key('irma_app_bar_leading')));
        await tester.tapAndSettle(find.byKey(const Key('open_settings_screen_button')));

        // Dev mode toggle should be gone now
        expect(find.byKey(const Key('dev_mode_toggle')), findsNothing);
      },
    );

    testWidgets('change-pin', (tester) async {
      await _initAndNavToSettingsScreen(tester);

      final changePinButtonFinder = find.text('Change PIN').hitTestable();
      await tester.scrollUntilVisible(changePinButtonFinder, 50);
      await tester.tapAndSettle(
        changePinButtonFinder,
        duration: const Duration(milliseconds: 750),
      );

      // Enter current pin PIN
      await enterPin(tester, '12345');

      // Enter new PIN
      await enterPin(tester, '54321');

      // Next button
      var nextButtonFinder = find
          .byKey(
            const Key('pin_next'),
          )
          .hitTestable();

      await tester.waitFor(nextButtonFinder);
      await tester.ensureVisible(nextButtonFinder);
      await tester.tapAndSettle(
        nextButtonFinder,
        duration: const Duration(milliseconds: 750),
      );

      // Enter new PIN (again)
      await enterPin(tester, '54321');

      // Press change
      await tester.tapAndSettle(find.byKey(
        const Key('dialog_confirm_button'),
      ));

      // Expect snack bar
      var snackBarFinder = find.byType(SnackBar);
      await tester.waitFor(
        snackBarFinder,
        timeout: const Duration(seconds: 15),
      );

      // Check text in snackbar
      expect(
        find.descendant(
          of: snackBarFinder,
          matching: find.text('Success! Your new PIN has been saved'),
        ),
        findsOneWidget,
      );

      // Wait for snackbar to disappear
      await tester.waitUntilDisappeared(
        snackBarFinder,
        timeout: const Duration(seconds: 10),
      );

      // Navigate to back to more tab
      await tester.tapAndSettle(find.byKey(const Key('irma_app_bar_leading')));

      // Logout
      final logoutButtonFinder = find.byKey(const Key('log_out_button')).hitTestable();
      await tester.scrollUntilVisible(logoutButtonFinder, 100);
      await tester.tapAndSettle(
        logoutButtonFinder,
        duration: const Duration(milliseconds: 750),
      );

      // Log back in with new pin
      await enterPin(tester, '54321');

      //Expect home screen
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('reset-from-settings', (tester) async {
      await _initAndNavToSettingsScreen(tester);

      var deleteFinder = find.byKey(const Key('delete_link'));

      // Tap on option to delete everything and start over
      await tester.scrollUntilVisible(deleteFinder, 75);
      await tester.tapAndSettle(deleteFinder);

      // Tap on the confirmation to delete all data
      await tester.tapAndSettle(find.text('Yes, delete everything'));

      // Check whether the enrollment screen is shown
      expect(find.byType(EnrollmentScreen), findsOneWidget);
    });

    testWidgets('change-language', (tester) async {
      await _initAndNavToSettingsScreen(tester);

      final changeLanguageLinkFinder = find.byKey(const Key('change_language_link'));

      // Tap on option to delete everything and start over
      await tester.scrollUntilVisible(changeLanguageLinkFinder, 75);
      await tester.tapAndSettle(changeLanguageLinkFinder);

      // Expect change language screen
      expect(find.byType(ChangeLanguageScreen), findsOneWidget);

      // Check the actual system app language
      final appFinder = find.byType(App);
      var appWidget = appFinder.evaluate().single.widget as App;
      expect(appWidget.forcedLocale?.languageCode, 'en');

      // Expect the language toggle be visible
      final systemLanguageToggleFinder = find.byKey(const Key('use_system_language_toggle'));
      expect(systemLanguageToggleFinder, findsOneWidget);

      // Find the actual toggle
      final systemLanguageSwitchFinder = find.descendant(
        of: systemLanguageToggleFinder,
        matching: find.byType(CupertinoSwitch),
      );

      // Expect the use system language toggle to be on
      expect(
        (systemLanguageSwitchFinder.evaluate().single.widget as CupertinoSwitch).value,
        true,
      );

      // System language radio should not be visible
      final systemLanguageRadioFinder = find.byKey(const Key('language_select'));
      expect(systemLanguageRadioFinder, findsNothing);

      // Tap on the toggle to turn off the use system language
      await tester.tapAndSettle(systemLanguageToggleFinder);

      // The system language radio should now be visible
      expect(systemLanguageRadioFinder, findsOneWidget);

      // Expect the use system language toggle to be off
      expect(
        (systemLanguageSwitchFinder.evaluate().single.widget as CupertinoSwitch).value,
        false,
      );

      // Press the option for Dutch
      await tester.tapAndSettle(find.text('Nederlands'));
      await tester.pumpAndSettle();

      // Refresh app widget
      appWidget = appFinder.evaluate().single.widget as App;

      // Language of the app should now be Dutch
      expect(appWidget.forcedLocale?.languageCode, 'nl');

      // This should be reflected in the app bar title
      final appBarFinder = find.byType(IrmaAppBar);
      expect(
        find.descendant(
          of: appBarFinder,
          matching: find.text('Taal'),
        ),
        findsOneWidget,
      );

      // Toggle the use system language again
      await tester.tapAndSettle(systemLanguageToggleFinder);

      // Refresh app widget
      appWidget = appFinder.evaluate().single.widget as App;

      // Language of the app should now be English again
      expect(appWidget.forcedLocale?.languageCode, 'en');

      // This should be reflected in the app bar title
      expect(
        find.descendant(
          of: appBarFinder,
          matching: find.text('Language'),
        ),
        findsOneWidget,
      );
    });
  });
}
