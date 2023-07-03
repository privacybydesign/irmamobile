import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/data/irma_mock_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attribute_value.dart';
import 'package:irmamobile/src/screens/notifications/bloc/notification/notifications_bloc.dart';
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

  test('delete-notification', () async {
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

    // Start loading old notifications
    bloc.add(LoadCachedNotifications());
    expect(await bloc.stream.first, isA<NotificationsLoading>());
    //

    // Notifications are done loading
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    // Start loading new notifications
    bloc.add(LoadNewNotifications());
    expect(await bloc.stream.first, isA<NotificationsLoading>());

    // Notifications are done loading
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    // Loaded state should have one notification
    final notificationsLoadedState = bloc.state as NotificationsLoaded;
    final notifications = notificationsLoadedState.notifications;
    expect(notifications.length, 1);

    // Delete the first (and only) notification
    final firstNotificationKey = notifications.first.key;
    bloc.add(DeleteNotification(firstNotificationKey));
    expect(await bloc.stream.first, isA<NotificationsLoading>());
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    expect(bloc.notifications.length, 0);
  });

  test('load-notifications-from-cache', () async {
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

    // Start loading old notifications
    bloc.add(LoadCachedNotifications());
    expect(await bloc.stream.first, isA<NotificationsLoading>());
    //

    // Notifications are done loading
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    // Start loading new notifications
    bloc.add(LoadNewNotifications());
    expect(await bloc.stream.first, isA<NotificationsLoading>());

    // Notifications are done loading
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    // Loaded state should have one notification
    final notificationsLoadedState = bloc.state as NotificationsLoaded;
    final notifications = notificationsLoadedState.notifications;
    expect(notifications.length, 1);

    // Now create a new bloc
    final bloc2 = NotificationsBloc(
      repo: repo,
    );

    // Start loading old notifications
    bloc2.add(LoadCachedNotifications());
    expect(await bloc2.stream.first, isA<NotificationsLoading>());

    // Notifications are done loading
    expect(await bloc2.stream.first, isA<NotificationsLoaded>());

    // Expect one notification to be there
    final notificationsLoadedState2 = bloc2.state as NotificationsLoaded;
    final notifications2 = notificationsLoadedState2.notifications;
    expect(notifications2.length, 1);

    // Now load new notifications
    bloc2.add(LoadNewNotifications());
    expect(await bloc2.stream.first, isA<NotificationsLoading>());

    // Notifications are done loading
    expect(await bloc2.stream.first, isA<NotificationsLoaded>());

    // Expect no new notifications to be there
    final notificationsLoadedState3 = bloc2.state as NotificationsLoaded;
    final notifications3 = notificationsLoadedState3.notifications;
    expect(notifications3.length, 1);
  });
}
