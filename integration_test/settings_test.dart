// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';

import 'helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

// TODO: These tests need to be updated for ux-2.0
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  Future<IrmaRepository> _initAndNavToSettingsScreen(WidgetTester tester) async {
    final repo = irmaBinding.repository;
    await tester.pumpWidgetAndSettle(IrmaApp(
      repository: repo,
    ));
    await unlock(tester);
    //Navigate to more tab
    await tester.tapAndSettle(find.byKey(const Key('nav_button_more')));
    //Open settings screen.
    await tester.tapAndSettle(find.byKey(const Key('open_settings_screen_button')));
    return repo;
  }

  group('irma-settings', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('navigate-to-settings-screen', (tester) async {
      await _initAndNavToSettingsScreen(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('settings-screen-content', (tester) async {
      // Initialize and open settings screen
      final repo = await _initAndNavToSettingsScreen(tester);

      // Check screen settings text
      const String textQRscanner = 'Open QR scanner automatically after start-up';
      const String textErrorReports = 'Send error reports to Yivi';
      const String textEnableScreenshots = 'Enable screenshots';
      final list = tester.getAllText(find.byType(ListView));
      expect(list, [
        textQRscanner,
        textErrorReports,
        'Developer mode',
        'Change your PIN',
        'Delete everything and start over',
        if (Platform.isAndroid) ...[
          textEnableScreenshots,
          'When enabled, the app will not be blurred in the app switcher.',
        ]
      ]);

      // Check the initial value of all settings.
      expect(tester.getSwitchListTileValue(find.text(textQRscanner)), false);
      expect(await repo.preferences.getStartQRScan().first, false);
      expect(tester.getSwitchListTileValue(find.text(textErrorReports)), false);
      expect(await repo.preferences.getStartQRScan().first, false);
      // Enable all settings.
      await tester.tapAndSettle(find.text(textQRscanner));
      await tester.tapAndSettle(find.text(textErrorReports));
      // Check whether all settings are enabled.
      expect(tester.getSwitchListTileValue(find.text(textQRscanner)), true);
      expect(await repo.preferences.getStartQRScan().first, true);
      expect(tester.getSwitchListTileValue(find.text(textErrorReports)), true);
      expect(await repo.preferences.getStartQRScan().first, true);
      // Only on Android, check setting to enable screenshots. On iOS, the option should not be there.
      if (Platform.isAndroid) {
        expect(tester.getSwitchListTileValue(find.text(textEnableScreenshots)), true);
        expect(await repo.preferences.getScreenshotsEnabled().first, true);
        await tester.tapAndSettle(find.text(textEnableScreenshots));
        expect(tester.getSwitchListTileValue(find.text(textEnableScreenshots)), false);
        expect(await repo.preferences.getScreenshotsEnabled().first, false);
      } else {
        expect(find.text(textEnableScreenshots), findsNothing);
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('change-PIN', (tester) async {
      // Initialize and open settings screen
      final repo = irmaBinding.repository;
      await tester.pumpWidgetAndSettle(IrmaApp(repository: repo));
      await unlock(tester);

      await tester.tapAndSettle(find.byKey(const Key('nav_button_more')));
      await tester.tapAndSettle(find.byKey(const Key('open_settings_screen_button')));
      // Tap on option to change PIN
      await tester.tapAndSettle(find.text('Change your PIN'));
      // Enter current PIN
      await tester.enterTextAtFocusedAndSettle('12345');
      // Enter new PIN
      await tester.enterTextAtFocusedAndSettle('54921');
      // Enter new PIN (again)
      await tester.enterTextAtFocusedAndSettle('54921');
      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.text('Change'),
      ));
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('delete-all-data', (tester) async {
      // Initialize and open settings screen
      final repo = irmaBinding.repository;
      await tester.pumpWidgetAndSettle(IrmaApp(repository: repo));
      await unlock(tester);

      // Scenario 3 of IRMA app settings
      // Open menu
      await tester.tapAndSettle(find.byKey(const Key('nav_button_more')));
      // Open settings
      await tester.tapAndSettle(find.text('Settings'));
      // Tap on option to delete everything and start over
      await tester.tapAndSettle(find.text('Delete everything and start over'));
      // Tap on the confirmation to delete all data
      await tester.tapAndSettle(find.text('Yes, delete everything'));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
