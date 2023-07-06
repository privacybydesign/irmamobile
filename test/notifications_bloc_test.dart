import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/data/irma_mock_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attribute_value.dart';
import 'package:irmamobile/src/screens/notifications/bloc/notifications_bloc.dart';
import 'package:irmamobile/src/screens/notifications/models/actions/credential_detail_navigation_action.dart';
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

  test('initalize-notifications', () async {
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
}
