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
}
