import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/screens/data/credentials_detail_screen.dart';
import 'package:irmamobile/src/screens/notifications/bloc/notifications_bloc.dart';
import 'package:irmamobile/src/screens/notifications/notifications_screen.dart';
import 'package:irmamobile/src/screens/notifications/widgets/notification_bell.dart';
import 'package:irmamobile/src/screens/notifications/widgets/notification_card.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_close_button.dart';
import 'package:irmamobile/src/widgets/yivi_themed_button.dart';

import 'helpers/helpers.dart';
import 'helpers/issuance_helpers.dart';
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

    // Mocked notification cache
    const mockedCredentialCache =
        '[{"id":"#55175","softDeleted":false,"read":false,"content":{"titleTranslationKey":"notifications.credential_status.revoked.title","messageTranslationKey":"notifications.credential_status.revoked.message","translationType":"internalTranslatedContent"},"timestamp":"2023-07-14T11:11:31.794803","credentialHash":"session-43-0","type":"revoked","credentialTypeId":"irma-demo.IRMATube.member","action":{"credentialTypeId":"irma-demo.IRMATube.member","actionType":"credentialDetailNavigationAction"},"notificationType":"credentialStatusNotification"}]';

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

      // Expect NotificationsScreen to appear
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
      await irmaBinding.repository.preferences.setSerializedNotifications(mockedCredentialCache);
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // Expect the NotificationBell to be visible
      expect(notificationBellFinder, findsOneWidget);

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

    testWidgets('read-all-notifications', (tester) async {
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
        read: false,
      );

      // Leave the screen by pressing the back button
      final backButtonFinder = find.byKey(const Key('irma_app_bar_leading'));
      await tester.tapAndSettle(backButtonFinder);

      // pumpAndSettle to make sure the event is processed
      await tester.pumpAndSettle();

      // NotificationBell now should not show the indicator
      final notificationBell2 = tester.widget<NotificationBell>(notificationBellFinder);
      expect(notificationBell2.showIndicator, false);

      // Press the NotificationBell and expect the NotificationsScreen to appear
      await tester.tapAndSettle(notificationBellFinder);
      expect(notificationsScreenFinder, findsOneWidget);

      // Expect one NotificationCard
      final notificationCardFinder2 = find.byType(NotificationCard);
      expect(notificationCardFinder2, findsOneWidget);

      // Evaluate the NotificationCard
      await evaluateNotificationCard(
        tester,
        notificationCardFinder2,
        title: 'Data revoked',
        content: 'Demo IRMATube has revoked this data: Demo IRMATube Member',
        read: true,
      );
    });

    testWidgets('dismiss-notification', (tester) async {
      await irmaBinding.repository.preferences.setSerializedNotifications(mockedCredentialCache);
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // Tap the bell, expect a notification card and dismiss it
      await tester.tapAndSettle(notificationBellFinder);
      expect(notificationsScreenFinder, findsOneWidget);

      final notificationCardFinder = find.byType(NotificationCard);
      expect(notificationCardFinder, findsOneWidget);

      await tester.drag(notificationCardFinder, const Offset(-500, 0));

      // pumpAndSettle to make sure the event is processed
      await tester.pumpAndSettle();

      // Expect no NotificationCard
      expect(notificationCardFinder, findsNothing);

      // Go back
      final backButtonFinder = find.byKey(const Key('irma_app_bar_leading'));
      await tester.tapAndSettle(backButtonFinder);

      // Go to the notifications screen again
      await tester.tapAndSettle(notificationBellFinder);

      // Expect no NotificationCard
      expect(notificationCardFinder, findsNothing);
    });

    testWidgets('notification-action', (tester) async {
      await irmaBinding.repository.preferences.setSerializedNotifications(mockedCredentialCache);
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // To make the action action work, we need to actually have the credential in the app
      await issueIrmaTubeMember(tester, irmaBinding);
      await tester.tapAndSettle(find.descendant(
        of: find.byType(YiviThemedButton),
        matching: find.text('OK'),
      ));

      // Tap the bell, expect a notification screen
      await tester.tapAndSettle(notificationBellFinder);
      expect(notificationsScreenFinder, findsOneWidget);

      // Evaluate the NotificationCard, it should be unread
      final notificationCardFinder = find.byType(NotificationCard);
      expect(notificationCardFinder, findsOneWidget);
      await evaluateNotificationCard(
        tester,
        notificationCardFinder,
        title: 'Data revoked',
        content: 'Demo IRMATube has revoked this data: Demo IRMATube Member',
        read: false,
      );

      // Now trigger the action by tapping the notification card
      await tester.tapAndSettle(notificationCardFinder);

      // Expect the credential detail screen
      final credentialDetailScreenFinder = find.byType(CredentialsDetailScreen);
      expect(credentialDetailScreenFinder, findsOneWidget);

      // Expect the actual credential card
      // Note: the credential card is not actually revoked, so the card does not reflect this.
      final credentialCardFinder = find.byType(IrmaCredentialCard);
      await evaluateCredentialCard(
        tester,
        credentialCardFinder.first,
        credentialName: 'Demo IRMATube Member',
        issuerName: 'Demo IRMATube',
      );

      // Go back
      final backButtonFinder = find.byKey(const Key('irma_app_bar_leading'));
      await tester.tapAndSettle(backButtonFinder);

      // Expect the notification screen
      expect(notificationsScreenFinder, findsOneWidget);

      // The notification should be marked as read
      final notificationCardFinder2 = find.byType(NotificationCard);
      expect(notificationCardFinder2, findsOneWidget);

      await evaluateNotificationCard(
        tester,
        notificationCardFinder2,
        title: 'Data revoked',
        content: 'Demo IRMATube has revoked this data: Demo IRMATube Member',
        read: true,
      );
    });

    testWidgets('reload-notifications', (tester) async {
      final repo = irmaBinding.repository;
      final notificationsBloc = NotificationsBloc(repo: repo);
      await pumpAndUnlockApp(tester, repo, null, notificationsBloc);

      // Make sure a revoked credential is present
      final revocationKey = generateRevocationKey();
      await issueCredentials(
        tester,
        irmaBinding,
        {'irma-demo.MijnOverheid.root.BSN': '12345'},
        revocationKeys: {'irma-demo.MijnOverheid.root': revocationKey},
      );

      // Close the add credential success screen
      await tester.tapAndSettle(
        find.text('OK'),
      );

      await revokeCredential('irma-demo.MijnOverheid.root', revocationKey);
      await irmaBinding.repository.startTestSession('''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.MijnOverheid.root.BSN" ]
            ]
          ],
          "revocation": [ "irma-demo.MijnOverheid.root" ]
        }
      ''');
      await tester.pumpAndSettle();
      await tester.tapAndSettle(find.byType(IrmaCloseButton));
      await tester.tapAndSettle(find.text('Close'));

      await tester.tapAndSettle(notificationBellFinder);
      expect(notificationsScreenFinder, findsOneWidget);

      // Expect no notificationCard cards
      final notificationCardsFinder = find.byType(NotificationCard);
      expect(notificationCardsFinder, findsNothing);

      // Now pull to refresh and expect a notification card
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(notificationCardsFinder, findsOneWidget);

      final notificationCardFinder = notificationCardsFinder.first;
      await evaluateNotificationCard(
        tester,
        notificationCardFinder,
        title: 'Data revoked',
        content: 'Demo MijnOverheid.nl has revoked this data: Demo Root',
        read: false,
      );

      // Tap the notification card to open the credential detail screen
      await tester.tapAndSettle(notificationCardFinder);

      // Expect the credential detail screen
      final credentialDetailScreenFinder = find.byType(CredentialsDetailScreen);
      expect(credentialDetailScreenFinder, findsOneWidget);

      // Expect the actual credential card
      final credentialCardsFinder = find.byType(IrmaCredentialCard);
      expect(credentialCardsFinder, findsOneWidget);

      final credentialCardFinder = credentialCardsFinder.first;
      await evaluateCredentialCard(
        tester,
        credentialCardFinder,
        credentialName: 'Demo Root',
        issuerName: 'Demo MijnOverheid.nl',
        attributes: {'BSN': '12345'},
        isRevoked: true,
      );

      // Go back
      final backButtonFinder = find.byKey(const Key('irma_app_bar_leading'));
      await tester.tapAndSettle(backButtonFinder);

      // Notification should be marked as read
      await evaluateNotificationCard(
        tester,
        notificationCardFinder,
        title: 'Data revoked',
        content: 'Demo MijnOverheid.nl has revoked this data: Demo Root',
        read: true,
      );
    });
  });
}
