import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/screens/notifications/notifications_screen.dart';
import 'package:irmamobile/src/screens/notifications/widgets/notification_bell.dart';
import 'package:irmamobile/src/screens/notifications/widgets/notification_card.dart';
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

    // Reusable finders
    final notificationsScreenFinder = find.byType(NotificationsScreen);
    final irmaAppBarFinder = find.byType(IrmaAppBar);

    // The NotificationBell should be findable in the app bar
    final notificationBellFinder = find.descendant(
      of: irmaAppBarFinder,
      matching: find.byType(NotificationBell),
    );

    testWidgets('reach', (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      // NotificationBell should be visible
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

      expect(notificationsScreenFinder, findsOneWidget);
    });

    testWidgets('empty-state', (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // Press the NotificationBell
      await tester.tapAndSettle(notificationBellFinder);
      expect(notificationsScreenFinder, findsOneWidget);

      // Expect page title
      final screenTitleFinder = find.descendant(
        of: find.byType(IrmaAppBar),
        matching: find.text('Notifications'),
      );
      expect(screenTitleFinder, findsOneWidget);

      // Expect empty state message
      final emptyStateMessageFinder = find.descendant(
        of: notificationsScreenFinder,
        matching: find.text('No notifications'),
      );
      expect(emptyStateMessageFinder, findsOneWidget);
    });

    testWidgets('filled-state', (tester) async {
      const mockedCredentialCache =
          '[{"id":"#55175","softDeleted":false,"content":{"titleTranslationKey":"notifications.credential_status.revoked.title","messageTranslationKey":"notifications.credential_status.revoked.message","translationType":"internalTranslatedContent"},"timestamp":"2023-07-14T11:11:31.794803","credentialHash":"session-43-0","type":"revoked","credentialTypeId":"irma-demo.IRMATube.member","notificationType":"credentialStatusNotification"}]';
      await irmaBinding.repository.preferences.setSerializedNotifications(mockedCredentialCache);

      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // Expect the NotificationBell to be visible
      final notificationBellFinder = find.descendant(
        of: find.byType(IrmaAppBar),
        matching: find.byType(NotificationBell),
      );
      expect(notificationBellFinder, findsOneWidget);

      // Notification bell should show the indicator
      final notificationBell = tester.widget<NotificationBell>(notificationBellFinder);
      expect(notificationBell.showIndicator, true);

      // Press the NotificationBell and expect the NotificationsScreen to appear
      await tester.tapAndSettle(notificationBellFinder);
      expect(notificationsScreenFinder, findsOneWidget);

      // Expect one NotificationCard
      final notificationCardFinder = find.byType(NotificationCard);
      expect(notificationCardFinder, findsOneWidget);

      // Evaluate the NotificationCard
      await evaluateNotificationCard(
        tester,
        notificationCardFinder,
        title: 'Data revoked',
        content: 'Demo IRMATube has revoked this data: Demo IRMATube Member',
      );
    });
  });
}
