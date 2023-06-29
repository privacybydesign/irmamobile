import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/data/irma_mock_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/notifications/bloc/credential_status_notification/credential_status_notification_cubit.dart';
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


  test('load-empty-cache', () async {
    // Create bloc
    final cubit = CredentialStatusNotificationCubit(
      repo: repo,
    );
    expect(cubit.state, isA<CredentialStatusNotificationInitial>());

    // Load from empty cache
    await cubit.loadCache();

    expect(cubit.credentialStatusNotifications.length, 0);
  });

  test('load-filled-cache', () async {
    // Create a json string with one credential status notification
    // This represents a notification that credential with 818626713 has been revoked
    const serializedCredentialStatusNotifications = '{"818626713":[0]}';
    await repo.preferences.setSerializedCredentialStatusNotifications(serializedCredentialStatusNotifications);

    // Create bloc
    final cubit = CredentialStatusNotificationCubit(
      repo: repo,
    );
    expect(cubit.state, isA<CredentialStatusNotificationInitial>());

    // Load from empty cache
    await cubit.loadCache();

    //  Expect one credential status notification in the cubit
    expect(cubit.credentialStatusNotifications.length, 1);
  });
}
