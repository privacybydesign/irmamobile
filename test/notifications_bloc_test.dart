import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/data/irma_mock_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attribute_value.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/notifications/bloc/notification/notifications_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('t1', () async {
    // Issue a revocable credential
    await _issueCredential(
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

    // Start loading notifications
    bloc.add(LoadNotifications());
    expect(await bloc.stream.first, isA<NotificationsLoading>());

    // Notifications are done loading
    expect(await bloc.stream.first, isA<NotificationsLoaded>());

    // Loaded state should have one notification
    final notificationsLoadedState = bloc.state as NotificationsLoaded;
    final notifications = notificationsLoadedState.notifications;
    expect(notifications.length, 1);
  });
}

Future<void> _issueCredential(
  IrmaRepository repo,
  IrmaMockBridge mockBridge,
  int sessionID,
  List<Map<String, TextValue>> credentials, {
  Duration validity = const Duration(days: 365),
  bool revoked = false,
}) async {
  mockBridge.mockIssuanceSession(
    sessionID,
    credentials,
    validity: validity,
    revoked: revoked,
  );

  repo.dispatch(
    NewSessionEvent(sessionID: sessionID, request: SessionPointer(irmaqr: 'issuing', u: '')),
    isBridgedEvent: true,
  );
  await repo
      .getSessionState(sessionID)
      .firstWhere((session) => session.status == SessionStatus.requestIssuancePermission);

  repo.dispatch(
    RespondPermissionEvent(sessionID: sessionID, proceed: true, disclosureChoices: [[]]),
    isBridgedEvent: true,
  );
  await repo.getSessionState(sessionID).firstWhere((session) => session.status == SessionStatus.success);
}
