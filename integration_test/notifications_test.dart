import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/screens/notifications/notifications_screen.dart';
import 'package:irmamobile/src/screens/notifications/widgets/notification_bell.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

import 'helpers/helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('notifications', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('reach', (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // Find the NotificationBell in the IrmaAppBar
      final notificationBellFinder = find.descendant(
        of: find.byType(IrmaAppBar),
        matching: find.byType(NotificationBell),
      );

      expect(notificationBellFinder, findsOneWidget);

      // Switch tabs. NotificationBell should still be visible
      await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));
      expect(notificationBellFinder, findsOneWidget);

      await tester.tapAndSettle(find.byKey(const Key('nav_button_activity')));
      expect(notificationBellFinder, findsOneWidget);

      await tester.tapAndSettle(find.byKey(const Key('nav_button_more')));
      expect(notificationBellFinder, findsOneWidget);

      // Finally, go back to the home tab
      await tester.tapAndSettle(find.byKey(const Key('nav_button_home')));

      // Press the NotificationBell
      await tester.tapAndSettle(notificationBellFinder);

      // expect NotificationsScreen to appear
      final notificationsScreenFinder = find.byType(NotificationsScreen);
      expect(notificationsScreenFinder, findsOneWidget);
    });
  });
}
