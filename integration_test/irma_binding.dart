import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/clear_all_data_event.dart';
import 'package:irmamobile/src/models/client_preferences.dart';
import 'package:irmamobile/src/models/enrollment_events.dart';
import 'package:irmamobile/src/models/enrollment_status.dart';

/// Binding to use the static IrmaClientBridge and IrmaPreferences in integration tests.
class IntegrationTestIrmaBinding {
  static IntegrationTestIrmaBinding? _instance;

  final IrmaClientBridge _bridge;

  final IrmaPreferences preferences;
  late IrmaRepository repository;

  IntegrationTestIrmaBinding._(this._bridge, this.preferences);

  factory IntegrationTestIrmaBinding.ensureInitialized() {
    _instance ??= IntegrationTestIrmaBinding._(
      IrmaClientBridge(),
      IrmaPreferences.get(),
    );
    return _instance!;
  }

  Future<void> setUp({EnrollmentStatus enrollmentStatus = EnrollmentStatus.enrolled}) async {
    assert(enrollmentStatus != EnrollmentStatus.undetermined);
    // Enable developer mode before enrollment, such that we can use a local keyshare server.
    _bridge.dispatch(ClientPreferencesEvent(clientPreferences: ClientPreferences(developerMode: true)));
    if (enrollmentStatus == EnrollmentStatus.enrolled) {
      _bridge.dispatch(EnrollEvent(email: '', pin: '12345', language: 'en'));
      preferences.setLongPin(false);
      await _bridge.events.firstWhere((event) => event is EnrollmentSuccessEvent);
    }

    repository = IrmaRepository(client: _bridge);

    if ((await repository.getIrmaConfiguration().first).schemeManagers.containsKey('pbdf')) {
      throw Exception('Integration tests should not be run using a production scheme');
    }

    await preferences.setAcceptedRootedRisk(true);
  }

  Future<void> tearDown() async {
    await repository.close();
    // Make sure there is a listener for the bridge events.
    final dataClearedFuture = _bridge.events
        .firstWhere((event) => event is EnrollmentStatusEvent && event.enrollmentStatus == EnrollmentStatus.unenrolled);
    _bridge.dispatch(ClearAllDataEvent());
    await preferences.clearAll();
    await dataClearedFuture;
  }
}
