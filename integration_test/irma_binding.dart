import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/clear_all_data_event.dart';
import 'package:irmamobile/src/models/client_preferences.dart';
import 'package:irmamobile/src/models/enrollment_events.dart';
import 'package:irmamobile/src/models/enrollment_status.dart';
import 'package:irmamobile/src/models/error_event.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/native_events.dart';
import 'package:irmamobile/src/models/scheme_events.dart';
import 'package:rxdart/rxdart.dart';

/// Binding to use the static IrmaClientBridge in integration tests.
class IntegrationTestIrmaBinding {
  static IntegrationTestIrmaBinding? _instance;

  final IrmaClientBridge _bridge;
  IrmaRepository? _repository;
  IrmaPreferences? _preferences;

  IrmaRepository get repository {
    if (_repository == null) throw Exception('IntegrationTestIrmaBinding has not been set up');
    return _repository!;
  }

  IntegrationTestIrmaBinding._(this._bridge);

  factory IntegrationTestIrmaBinding.ensureInitialized() {
    _instance ??= IntegrationTestIrmaBinding._(
      IrmaClientBridge(debugLogging: true),
    );
    return _instance!;
  }

  Future<void> setUp({EnrollmentStatus enrollmentStatus = EnrollmentStatus.enrolled}) async {
    assert(enrollmentStatus != EnrollmentStatus.undetermined);
    _preferences ??= await IrmaPreferences.fromInstance();

    _bridge.dispatch(AppReadyEvent());
    EnrollmentStatusEvent currEnrollmentStatus = await _expectBridgeEventGuarded<EnrollmentStatusEvent>();

    // Ensure the app is not enrolled to its keyshare server yet.
    if (currEnrollmentStatus.enrolledSchemeManagerIds.isNotEmpty) {
      await tearDown();
    }

    // Ensure test scheme is available.
    if (!currEnrollmentStatus.unenrolledSchemeManagerIds.contains('test')) {
      _bridge.dispatch(InstallSchemeEvent(
        url: 'https://drksn.nl/irma_configuration/test',
        publicKey:
            '-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAErWv2+LXHsFQvLZ7udfpatUebiQV3\nAKJq92/3Qv8GErrRWuNkLd3D/LBZZrpuZ95xAb/GfoCCXrT0cUGESQ9JIA==\n-----END PUBLIC KEY-----',
      ));
      currEnrollmentStatus = await _expectBridgeEventGuarded<EnrollmentStatusEvent>();
      if (!currEnrollmentStatus.unenrolledSchemeManagerIds.contains('test')) {
        throw Exception('No test scheme installed');
      }
    }

    // Enable developer mode before initializing repository, such that we can use a local keyshare server.
    _bridge.dispatch(ClientPreferencesEvent(clientPreferences: ClientPreferences(developerMode: true)));

    // Enable screenshots to make sure screen recordings can be made.
    await _preferences!.setScreenshotsEnabled(true);

    // Prevent rooted warning to be shown on simulators.
    await _preferences!.setAcceptedRootedRisk(true);

    // Ensure enrollment status is set as expected.
    if (enrollmentStatus == EnrollmentStatus.enrolled) {
      _bridge.dispatch(EnrollEvent(
        email: '',
        pin: '12345',
        language: 'en',
        schemeId: 'test',
      ));
      await _preferences!.setLongPin(false);
      await _expectBridgeEventGuarded((event) => event is EnrollmentSuccessEvent);
    }

    await _preferences!.setAcceptedRootedRisk(true);

    _repository = IrmaRepository(
      client: _bridge,
      preferences: _preferences!,
      defaultKeyshareScheme: 'test',
    );
  }

  Future<void> tearDown() async {
    await _repository?.close();
    _repository = null;
    // Make sure there is a listener for the bridge events.
    final dataClearedFuture =
        _expectBridgeEventGuarded<EnrollmentStatusEvent>((event) => event.enrolledSchemeManagerIds.isEmpty);
    _bridge.dispatch(ClearAllDataEvent());
    await _preferences?.clearAll();
    await dataClearedFuture;
  }

  /// Returns the first bridge event that matches the given event type and test conditions.
  /// The bridge event stream is guarded while waiting to detect relevant errors.
  Future<T> _expectBridgeEventGuarded<T extends Event>([bool Function(T)? test]) => _bridge.events
      .where((event) {
        if (event is ErrorEvent) throw Exception(event.toString());
        if (event is EnrollmentFailureEvent) throw Exception(event.error);
        return event is T;
      })
      .whereType<T>()
      .where(test ?? (_) => true)
      .first;
}
