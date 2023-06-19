import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/data/irma_mock_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/notifications/bloc/notifications_bloc.dart';
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

    // Notifications are done loading



  });
}
