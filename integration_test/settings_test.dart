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

  group('irma-settings', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('screentest', (tester) async {
      // Scenario 1 of IRMA app settings
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp());
      await unlock(tester);
      // Open menu
      await tester.tapAndSettle(find.byKey(const Key('open_menu_icon')));
      // Open menu_settings
      await tester.tapAndSettle(find.text('Settings'));
      // Check screen settings text
      String textQRscanner = 'Open QR scanner automatically after start-up';
      String textErrorReports = 'Send error reports to IRMA';
      final list = tester.getAllText(find.byType(ListView));
      expect(list, [
        textQRscanner,
        'Change your PIN',
        'Advanced',
        textErrorReports,
        'Delete everything and start over',
      ]);
      // Check the options and enabled the option 'open QR scanner automatically after-start-up'
      expect(tester.getSwitchListTileValue(find.text(textQRscanner)), false);
      expect(await irmaBinding.preferences.getStartQRScan().first, false);
      expect(tester.getSwitchListTileValue(find.text(textErrorReports)), false);
      expect(await irmaBinding.preferences.getStartQRScan().first, false);
      await tester.tapAndSettle(find.text(textQRscanner));
      await tester.tapAndSettle(find.text(textErrorReports));
      expect(tester.getSwitchListTileValue(find.text(textQRscanner)), true);
      expect(await irmaBinding.preferences.getStartQRScan().first, true);
      // Enabled the option 'Send error reports to IRMA'
      expect(tester.getSwitchListTileValue(find.text(textErrorReports)), true);
      expect(await irmaBinding.preferences.getStartQRScan().first, true);
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('change-PIN', (tester) async {
      // Scenario 2 of IRMA app settings
      await tester.pumpWidgetAndSettle(IrmaApp());
      await unlock(tester);
      // Open menu
      await tester.tapAndSettle(find.byKey(const Key('open_menu_icon')));
      // Open menu settings
      await tester.tapAndSettle(find.text('Settings'));
      // Open settings change-PIN
      await tester.tapAndSettle(find.text('Change your PIN'));
      // Enter current PIN
      await tester.enterTextAtFocusedAndSettle('12345');
      // Enter new PIN
      await tester.waitFor(find.text('Choose your new PIN'));
      await tester.enterTextAtFocusedAndSettle('54321');
      // Enter new PIN (again)
      await tester.waitFor(find.text('Enter your PIN one more time.'));
      await tester.enterTextAtFocusedAndSettle('54321');
      await tester.pumpAndSettle();
      // Check if Change-PIN is succeed
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
      // Check whether login is succeeded
      await tester.waitFor(find.byKey(const Key('pin_screen')));
      await tester.enterTextAtFocusedAndSettle('54321');
      await tester.tapAndSettle(find.byKey(const Key('menu_logout_icon')));
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('delete-all-data', (tester) async {
      // Scenario 3 of IRMA app settings
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp());
      await unlock(tester);
      // Open menu
      await tester.tapAndSettle(find.byKey(const Key('open_menu_icon')));
      // Open menu settings
      await tester.tapAndSettle(find.text('Settings'));
      // Tap setting on Delete everything and start over
      await tester.tapAndSettle(find.text('Delete everything and start over'));
      // Click on the confirmation to delete-all-data
      await tester.tapAndSettle(find.text('Yes, delete everything'));
      // Check if you on the enrollment info screen
      await tester.waitFor(find.byKey(const Key('enrollment_p1')));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
