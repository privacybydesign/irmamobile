// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'dart:io';

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

  group('irma-settings', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('screentest', (tester) async {
      // Scenario 1 of IRMA app settings
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(const IrmaApp());
      await unlock(tester);
      // Open menu
      await tester.tapAndSettle(find.byKey(const Key('open_menu_icon')));
      // Open settings
      await tester.tapAndSettle(find.text('Settings'));
      // Check screen settings text
      String textQRscanner = 'Open QR scanner automatically after start-up';
      String textErrorReports = 'Send error reports to IRMA';
      String textEnableScreenshots = 'Enable screenshots';
      final list = tester.getAllText(find.byType(ListView));
      expect(list, [
        textQRscanner,
        'Change your PIN',
        'Advanced',
        textErrorReports,
        'Delete everything and start over',
        if (Platform.isAndroid)
          {
            textEnableScreenshots,
            'When enabled, the app will not be blurred in the app switcher.',
          }
      ]);
      // Check the initial value of all settings.
      expect(tester.getSwitchListTileValue(find.text(textQRscanner)), false);
      expect(await irmaBinding.preferences.getStartQRScan().first, false);
      expect(tester.getSwitchListTileValue(find.text(textErrorReports)), false);
      expect(await irmaBinding.preferences.getStartQRScan().first, false);
      // Enable all settings.
      await tester.tapAndSettle(find.text(textQRscanner));
      await tester.tapAndSettle(find.text(textErrorReports));
      // Check whether all settings are enabled.
      expect(tester.getSwitchListTileValue(find.text(textQRscanner)), true);
      expect(await irmaBinding.preferences.getStartQRScan().first, true);
      expect(tester.getSwitchListTileValue(find.text(textErrorReports)), true);
      expect(await irmaBinding.preferences.getStartQRScan().first, true);
      // Only on Android, check setting to enable screenshots. On iOS, the option should not be there.
      if (Platform.isAndroid) {
        expect(tester.getSwitchListTileValue(find.text(textEnableScreenshots)), false);
        expect(await irmaBinding.preferences.getScreenshotsEnabled().first, false);
        await tester.tapAndSettle(find.text(textEnableScreenshots));
        expect(tester.getSwitchListTileValue(find.text(textEnableScreenshots)), true);
        expect(await irmaBinding.preferences.getScreenshotsEnabled().first, true);
      } else {
        expect(find.text(textEnableScreenshots), findsNothing);
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('change-PIN', (tester) async {
      // Scenario 2 of IRMA app settings
      await tester.pumpWidgetAndSettle(const IrmaApp());
      await unlock(tester);
      // Open menu
      await tester.tapAndSettle(find.byKey(const Key('open_menu_icon')));
      // Open settings
      await tester.tapAndSettle(find.text('Settings'));
      // Tap on option to change PIN
      await tester.tapAndSettle(find.text('Change your PIN'));
      // Enter current PIN
      await tester.enterTextAtFocusedAndSettle('12345');
      // Enter new PIN
      await tester.waitFor(find.text('Choose your new PIN'));
      await tester.enterTextAtFocusedAndSettle('54321');
      // Enter new PIN (again)
      await tester.waitFor(find.text('Enter your PIN one more time.'));
      await tester.enterTextAtFocusedAndSettle('54321');
      await tester.waitFor(find.text('Success'));
      // Check whether changing the PIN has succeeded
      final column = tester.getAllText(find.byType(Column));
      expect(column, [
        'Success',
        'Your PIN has been changed.',
        'OK',
      ]);
      await tester.tapAndSettle(find.text('OK'));
      await tester.tapAndSettle(find.byKey(const Key('irma_app_bar_leading')));
      // Log out
      await tester.tapAndSettle(find.byKey(const Key('menu_logout_icon')));
      // Check whether login has succeeded
      await tester.waitFor(find.byKey(const Key('pin_screen')));
      await tester.enterTextAtFocusedAndSettle('54321');
      await tester.tapAndSettle(find.byKey(const Key('menu_logout_icon')));
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('delete-all-data', (tester) async {
      // Scenario 3 of IRMA app settings
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(const IrmaApp());
      await unlock(tester);
      // Open menu
      await tester.tapAndSettle(find.byKey(const Key('open_menu_icon')));
      // Open settings
      await tester.tapAndSettle(find.text('Settings'));
      // Tap on option to delete everything and start over
      await tester.tapAndSettle(find.text('Delete everything and start over'));
      // Tap on the confirmation to delete all data
      await tester.tapAndSettle(find.text('Yes, delete everything'));
      // Check whether the enrollment info screen is shown
      await tester.waitFor(find.byKey(const Key('enrollment_p1')));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
