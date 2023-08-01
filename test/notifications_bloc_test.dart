import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/data/irma_mock_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attribute_value.dart';
import 'package:irmamobile/src/screens/notifications/bloc/notifications_bloc.dart';
import 'package:irmamobile/src/screens/notifications/models/actions/credential_detail_navigation_action.dart';
import 'package:irmamobile/src/screens/notifications/models/credential_status_notification.dart';
import 'package:irmamobile/src/screens/notifications/models/notification_translated_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/helpers.dart';

void main() {
  late IrmaRepository repo;
  late IrmaMockBridge mockBridge;

  const serializedCredentials =
      '[{"id":"#55175","softDeleted":false,"read":false,"content":{"titleTranslationKey":"notifications.credential_status.revoked.title","messageTranslationKey":"notifications.credential_status.revoked.message","translationType":"internalTranslatedContent"},"timestamp":"2023-07-14T11:11:31.794803","credentialHash":"session-43-0","type":"revoked","credentialTypeId":"irma-demo.IRMATube.member","action":{"credentialTypeId":"irma-demo.IRMATube.member","actionType":"credentialDetailNavigationAction"},"notificationType":"credentialStatusNotification"}]';

  setUp(() async {
    mockBridge = IrmaMockBridge();
    SharedPreferences.setMockInitialValues({});

    repo = IrmaRepository(
      client: mockBridge,
      preferences: await IrmaPreferences.fromInstance(),
    );
    await repo.getCredentials().first; // Wait until AppReadyEvent has been processed.
  });

  tearDown(() async {
    await mockBridge.close();
    await repo.preferences.clearAll();
    await repo.close();
  });

  test('initialize-notifications', () async {
    // Issue a revocable credential
    await issueCredential(
      repo,
      mockBridge,
      43,
      [
        {
          'irma-demo.IRMATube.member.id': TextValue.fromString('12345'),
          'irma-demo.IRMATube.member.type': TextValue.fromString('member'),
        }
      ],
      revoked: true,
    );

    // Create bloc
    final bloc = NotificationsBloc(
      repo: repo,
    );
    expect(bloc.state, isA<NotificationsInitial>());

    bloc.add(Initialize());
    expect(await bloc.stream.first, isA<NotificationsLoading>());
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    // Loaded state should have one notification
    final notificationsLoadedState = bloc.state as NotificationsLoaded;
    final notifications = notificationsLoadedState.notifications;
    expect(notifications.length, 1);

    // The first notification should have an action of type CredentialDetailNavigationAction
    final firstNotification = notifications.first;
    expect(firstNotification.action, isA<CredentialDetailNavigationAction>());

    // And the action should have the correct credential type ID
    final credentialDetailNavigationAction = firstNotification.action as CredentialDetailNavigationAction;
    expect(credentialDetailNavigationAction.credentialTypeId, 'irma-demo.IRMATube.member');

    // The credential have the right content
    final notificationContent = firstNotification.content as InternalTranslatedContent;

    expect(notificationContent.titleTranslationKey, 'notifications.credential_status.revoked.title');
    expect(notificationContent.messageTranslationKey, 'notifications.credential_status.revoked.message');
  });

  test('reload-notifications', () async {
    // Issue a revocable credential
    await issueCredential(
      repo,
      mockBridge,
      43,
      [
        {
          'irma-demo.IRMATube.member.id': TextValue.fromString('12345'),
          'irma-demo.IRMATube.member.type': TextValue.fromString('member'),
        }
      ],
      revoked: true,
    );

    // Create bloc
    final bloc = NotificationsBloc(
      repo: repo,
    );
    expect(bloc.state, isA<NotificationsInitial>());

    bloc.add(Initialize());
    expect(await bloc.stream.first, isA<NotificationsLoading>());
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    // Loaded state should have one notification
    final notificationsLoadedState = bloc.state as NotificationsLoaded;
    final notifications = notificationsLoadedState.notifications;
    expect(notifications.length, 1);

    // Issue a second revoked credential
    await issueCredential(
      repo,
      mockBridge,
      44,
      [
        {
          'irma-demo.IRMATube.member.id': TextValue.fromString('56789'),
          'irma-demo.IRMATube.member.type': TextValue.fromString('member'),
        }
      ],
      revoked: true,
    );

    // Now reload the notifications
    bloc.add(LoadNotifications());
    expect(await bloc.stream.first, isA<NotificationsLoading>());
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    // Loaded state should now have two notifications
    final notificationsLoadedState2 = bloc.state as NotificationsLoaded;
    final notifications2 = notificationsLoadedState2.notifications;
    expect(notifications2.length, 2);
  });

  test('clean-up-notifications', () async {
    // Issue a revocable credential
    await issueCredential(
      repo,
      mockBridge,
      43,
      [
        {
          'irma-demo.IRMATube.member.id': TextValue.fromString('12345'),
          'irma-demo.IRMATube.member.type': TextValue.fromString('member'),
        }
      ],
      revoked: true,
    );

    // Create bloc
    final bloc = NotificationsBloc(
      repo: repo,
    );
    expect(bloc.state, isA<NotificationsInitial>());

    bloc.add(Initialize());
    expect(await bloc.stream.first, isA<NotificationsLoading>());
    expect(await bloc.stream.first, isA<NotificationsInitialized>());

    // Loaded state should have one notification
    final notificationsLoadedState = bloc.state as NotificationsLoaded;
    final notifications = notificationsLoadedState.notifications;
    expect(notifications.length, 1);

    // Notification should be of type CredentialStatusNotification
    expect(notifications.first, isA<CredentialStatusNotification>());
    final notification = notifications.first as CredentialStatusNotification;

    bloc.add(SoftDeleteNotification(
      notification.id,
    ));
    expect(await bloc.stream.first, isA<NotificationsLoading>());
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    // Expect no notifications
    final notificationsLoadedState2 = bloc.state as NotificationsLoaded;
    final notifications2 = notificationsLoadedState2.notifications;
    expect(notifications2.length, 0);

    // Create another repo that has no credentials, with the same preferences
    // This should load the notifications from the preferences
    // But the clean up should remove the notification
    final repo2 = IrmaRepository(
      client: IrmaMockBridge(),
      preferences: repo.preferences,
    );

    final credentials = await repo2.getCredentials().first; // Wait until AppReadyEvent has been processed.
    expect(credentials.length, 0);

    // Create bloc
    final bloc2 = NotificationsBloc(
      repo: repo2,
    );
    expect(bloc2.state, isA<NotificationsInitial>());

    bloc2.add(Initialize());
    expect(await bloc2.stream.first, isA<NotificationsLoading>());
    expect(await bloc2.stream.first, isA<NotificationsInitialized>());

    // Loaded state should have no notifications
    final notificationsLoadedState3 = bloc2.state as NotificationsLoaded;
    final notifications3 = notificationsLoadedState3.notifications;
    expect(notifications3.length, 0);
  });

  test('load-valid-cache', () async {
    repo.preferences.setSerializedNotifications(serializedCredentials);

    // Create bloc
    final bloc = NotificationsBloc(
      repo: repo,
    );
    expect(bloc.state, isA<NotificationsInitial>());
    bloc.add(Initialize());

    // Expect a notifications
    expect(await bloc.stream.first, isA<NotificationsLoading>());
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    final notificationsLoadedState = bloc.state as NotificationsLoaded;
    final notifications = notificationsLoadedState.notifications;
    expect(notifications.length, 1);

    // Notification should be of type CredentialStatusNotification
    final notification = notifications.first;
    expect(notification, isA<CredentialStatusNotification>());
    final credentialStatusNotification = notification as CredentialStatusNotification;

    // Check the credential status notification fields
    expect(credentialStatusNotification.id, '#55175');
    expect(credentialStatusNotification.timestamp, DateTime.parse('2023-07-14T11:11:31.794803'));
    expect(credentialStatusNotification.softDeleted, false);
    expect(credentialStatusNotification.credentialHash, 'session-43-0');
    expect(credentialStatusNotification.type, CredentialStatusNotificationType.revoked);
    expect(credentialStatusNotification.content, isA<InternalTranslatedContent>());

    // Check the credential status notification content fields
    final credentialStatusNotificationContent = credentialStatusNotification.content as InternalTranslatedContent;
    expect(credentialStatusNotificationContent.titleTranslationKey, 'notifications.credential_status.revoked.title');
    expect(
        credentialStatusNotificationContent.messageTranslationKey, 'notifications.credential_status.revoked.message');
  });

  test('load-corrupted-cache', () async {
    const corruptedSerializedCredentials = 'THIS_IS_NOT_JSON';
    repo.preferences.setSerializedNotifications(corruptedSerializedCredentials);

    // Create bloc
    final bloc = NotificationsBloc(
      repo: repo,
    );
    expect(bloc.state, isA<NotificationsInitial>());
    bloc.add(Initialize());

    // Expect no notifications
    expect(await bloc.stream.first, isA<NotificationsLoading>());
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    final notificationsLoadedState = bloc.state as NotificationsLoaded;
    final notifications = notificationsLoadedState.notifications;
    expect(notifications.length, 0);
  });

  test('mark-all-notifications-as-read', () async {
    repo.preferences.setSerializedNotifications(serializedCredentials);

    // Create bloc
    final bloc = NotificationsBloc(
      repo: repo,
    );
    expect(bloc.state, isA<NotificationsInitial>());
    bloc.add(Initialize());

    // Expect a notifications
    expect(await bloc.stream.first, isA<NotificationsLoading>());
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    final notificationsLoadedState = bloc.state as NotificationsLoaded;
    final notifications = notificationsLoadedState.notifications;
    expect(notifications.length, 1);

    // Notifications should be unread
    final notification = notifications.first;
    expect(notification.read, false);

    // Mark notifications as read
    bloc.add(MarkAllNotificationsAsRead());
    expect(await bloc.stream.first, isA<NotificationsLoading>());
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    // Notifications should be read
    final notificationsLoadedState2 = bloc.state as NotificationsLoaded;
    final notifications2 = notificationsLoadedState2.notifications;
    expect(notifications2.length, 1);

    final notification2 = notifications2.first;
    expect(notification2.read, true);
  });

  test('mark-single-notification-as-read', () async {
    repo.preferences.setSerializedNotifications(serializedCredentials);

    // Create bloc
    final bloc = NotificationsBloc(
      repo: repo,
    );
    expect(bloc.state, isA<NotificationsInitial>());
    bloc.add(Initialize());

    // Expect a notifications
    expect(await bloc.stream.first, isA<NotificationsLoading>());
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    final notificationsLoadedState = bloc.state as NotificationsLoaded;
    final notifications = notificationsLoadedState.notifications;
    expect(notifications.length, 1);

    // Notifications should be unread
    final notification = notifications.first;
    expect(notification.read, false);

    // Mark notifications as read
    bloc.add(MarkNotificationAsRead(notification.id));

    expect(await bloc.stream.first, isA<NotificationsLoading>());
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    // Notifications should be read
    final notificationsLoadedState2 = bloc.state as NotificationsLoaded;
    final updatedNotifications = notificationsLoadedState2.notifications;
    expect(updatedNotifications.length, 1);

    final updatedNotification = updatedNotifications.first;
    expect(updatedNotification.read, true);
  });
}
