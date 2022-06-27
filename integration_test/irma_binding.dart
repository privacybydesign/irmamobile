import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/clear_all_data_event.dart';
import 'package:irmamobile/src/models/client_preferences.dart';
import 'package:irmamobile/src/models/enrollment_events.dart';
import 'package:irmamobile/src/models/enrollment_status.dart';
import 'package:irmamobile/src/models/native_events.dart';
import 'package:irmamobile/src/models/scheme_events.dart';
import 'package:rxdart/rxdart.dart';

/// Binding to use the static IrmaClientBridge in integration tests.
class IntegrationTestIrmaBinding {
  static IntegrationTestIrmaBinding? _instance;

  final IrmaClientBridge _bridge;

  late IrmaRepository repository;

  IntegrationTestIrmaBinding._(this._bridge);

  factory IntegrationTestIrmaBinding.ensureInitialized() {
    _instance ??= IntegrationTestIrmaBinding._(
      IrmaClientBridge(),
    );
    return _instance!;
  }

  Future<void> setUp({EnrollmentStatus enrollmentStatus = EnrollmentStatus.enrolled}) async {
    assert(enrollmentStatus != EnrollmentStatus.undetermined);
    final preferences = await IrmaPreferences.fromInstance();

    // Enable developer mode before initializing repository, such that we can use a local keyshare server.
    _bridge.dispatch(ClientPreferencesEvent(clientPreferences: ClientPreferences(developerMode: true)));

    // Ensure test scheme is available.
    _bridge.dispatch(AppReadyEvent());
    EnrollmentStatusEvent currEnrollmentStatus = await _bridge.events.whereType<EnrollmentStatusEvent>().first;
    if (!currEnrollmentStatus.unenrolledSchemeManagerIds.contains('test')) {
      _bridge.dispatch(InstallSchemeEvent(
        url: 'https://drksn.nl/irma_configuration/test',
        publicKey:
            '-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAErWv2+LXHsFQvLZ7udfpatUebiQV3\nAKJq92/3Qv8GErrRWuNkLd3D/LBZZrpuZ95xAb/GfoCCXrT0cUGESQ9JIA==\n-----END PUBLIC KEY-----',
      ));
      currEnrollmentStatus = await _bridge.events.whereType<EnrollmentStatusEvent>().first;
      if (!currEnrollmentStatus.unenrolledSchemeManagerIds.contains('test')) {
        throw Exception('No test scheme installed');
      }
    }

    // Ensure enrollment status is set as expected.
    if (enrollmentStatus == EnrollmentStatus.enrolled) {
      _bridge.dispatch(EnrollEvent(
        email: '',
        pin: '12345',
        language: 'en',
        schemeId: 'test',
      ));
      preferences.setLongPin(false);
      await _bridge.events.firstWhere((event) => event is EnrollmentSuccessEvent);
    }

    repository = IrmaRepository(
      client: _bridge,
      preferences: preferences,
      defaultKeyshareScheme: 'test',
    );

    await preferences.setAcceptedRootedRisk(true);
  }

  Future<void> tearDown() async {
    await repository.close();
    // Make sure there is a listener for the bridge events.
    final dataClearedFuture =
        _bridge.events.firstWhere((event) => event is EnrollmentStatusEvent && event.enrolledSchemeManagerIds.isEmpty);
    _bridge.dispatch(ClearAllDataEvent());
    await repository.preferences.clearAll();
    await dataClearedFuture;
  }
}
