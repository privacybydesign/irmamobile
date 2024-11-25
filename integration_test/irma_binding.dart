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
import 'package:irmamobile/src/util/security_context_binding.dart';
import 'package:rxdart/rxdart.dart';

/// Binding to use the static IrmaClientBridge in integration tests.
class IntegrationTestIrmaBinding {
  static const String _testKeyshareSchemeId = 'pbdf-staging';
  static const String _testKeyshareSchemeUrl = 'https://schemes.staging.yivi.app/pbdf-staging/';
  static const String _testKeyshareSchemePublicKey = '''
-----BEGIN PUBLIC KEY-----
MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEOcIdNBdagVt4+obhRPsyS5K2ovGKENYW
iHcQ8HxZ7lYoPRfabEpqv+3zsbxb4RlHXJ0dIgPkcp2sLFJZ9VDBAvcZlohWGYRW
Nu1bRk5gLEwmR5+V6MSFQWyWBkwacOt8
-----END PUBLIC KEY-----
''';

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
    SecurityContextBinding.ensureInitialized();
    _instance ??= IntegrationTestIrmaBinding._(
      IrmaClientBridge(debugLogging: true),
    );
    return _instance!;
  }

  Future<void> setUp({EnrollmentStatus enrollmentStatus = EnrollmentStatus.enrolled}) async {
    assert(enrollmentStatus != EnrollmentStatus.undetermined);
    _preferences ??= await IrmaPreferences.fromInstance();

    _bridge.dispatch(AppReadyEvent());
    EnrollmentStatusEvent currEnrollmentStatus = await _expectBridgeEventGuarded<EnrollmentStatusEvent>(
      (event) => event is ClientPreferencesEvent,
    );

    // Ensure the app is not enrolled to its keyshare server yet.
    if (currEnrollmentStatus.enrolledSchemeManagerIds.isNotEmpty) {
      await tearDown();
      _bridge.dispatch(AppReadyEvent());
      currEnrollmentStatus = await _expectBridgeEventGuarded<EnrollmentStatusEvent>(
        (event) => event is ClientPreferencesEvent,
      );
    }

    // Ensure test scheme is available.
    if (!currEnrollmentStatus.unenrolledSchemeManagerIds.contains(_testKeyshareSchemeId)) {
      _bridge.dispatch(InstallSchemeEvent(
        url: _testKeyshareSchemeUrl,
        publicKey: _testKeyshareSchemePublicKey,
      ));
      currEnrollmentStatus = await _expectBridgeEventGuarded<EnrollmentStatusEvent>();
      if (!currEnrollmentStatus.unenrolledSchemeManagerIds.contains(_testKeyshareSchemeId)) {
        throw Exception('No test scheme installed');
      }
    }

    // Enable developer mode before initializing repository, such that we can use a local keyshare server.
    _bridge.dispatch(ClientPreferencesEvent(clientPreferences: ClientPreferences(developerMode: true)));

    // Enable screenshots to make sure screen recordings can be made.
    await _preferences!.setScreenshotsEnabled(true);

    // Prevent rooted warning to be shown on simulators.
    await _preferences!.setAcceptedRootedRisk(true);

    // Always set ShowNameChangedNotification to false when testing
    await _preferences!.setShowNameChangedNotification(false);

    // Ensure enrollment status is set as expected.
    if (enrollmentStatus == EnrollmentStatus.enrolled) {
      _bridge.dispatch(EnrollEvent(
        email: '',
        pin: '12345',
        language: 'en',
        schemeId: _testKeyshareSchemeId,
      ));
      await _preferences!.setLongPin(false);
      await _expectBridgeEventGuarded((event) => event is EnrollmentSuccessEvent);
    }

    await _preferences!.setAcceptedRootedRisk(true);

    _repository = IrmaRepository(
      client: _bridge,
      preferences: _preferences!,
      defaultKeyshareScheme: _testKeyshareSchemeId,
    );
  }

  Future<void> tearDown() async {
    await _repository?.close();
    _repository = null;
    // Make sure there is a listener for the bridge events.
    final dataClearedFuture = _expectBridgeEventGuarded<EnrollmentStatusEvent>(
      (event) => event is EnrollmentStatusEvent && event.enrolledSchemeManagerIds.isEmpty,
    );
    _bridge.dispatch(ClearAllDataEvent());
    await _preferences?.clearAll();
    await dataClearedFuture;
  }

  /// Takes bridge events until an event is received that matches the given test conditions and
  /// returns the closest event in time that matches the expected return type.
  /// The bridge event stream is guarded while waiting to detect relevant errors.
  Future<T> _expectBridgeEventGuarded<T extends Event>([bool Function(Event)? test]) => _bridge.events
      .takeWhileInclusive((event) {
        if (event is ErrorEvent) throw Exception(event.toString());
        if (event is EnrollmentFailureEvent) throw Exception(event.error);
        if (test == null) return event is! T;
        return !test(event);
      })
      .toList()
      .then((receivedEvents) => receivedEvents.whereType<T>().last);
}
