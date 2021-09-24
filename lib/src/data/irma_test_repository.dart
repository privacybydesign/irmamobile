import 'package:irmamobile/src/models/clear_all_data_event.dart';
import 'package:irmamobile/src/models/enrollment_status.dart';

import 'irma_client_bridge.dart';
import 'irma_preferences.dart';
import 'irma_repository.dart';

class IrmaTestRepository {
  static IrmaTestRepository? _instance;

  final IrmaRepository inner;
  final IrmaPreferences preferences;

  IrmaTestRepository._(this.inner, this.preferences);

  static Future<IrmaTestRepository> ensureInitialized() async {
    if (_instance == null) {
      final repo = IrmaRepository(client: IrmaClientBridge());
      final pref = IrmaPreferences.get();

      // Wait until the bridge responds as an indication that the bridge is fully active.
      await repo.bridge.events.first;

      // The scheme's KeyshareAttribute field is not fully accurate, so
      // we do an educated guess for additional myIRMA credentials.
      final config = await repo.getIrmaConfiguration().first;
      config.credentialTypes.forEach((_, cred) {
        final schemeManager = config.schemeManagers[cred.schemeManagerId]!;
        final keyshareAttr = schemeManager.keyshareAttribute.split('.');
        final keyshareCred = keyshareAttr.length == 4 ? keyshareAttr.sublist(0, 3).join('.') : '';
        if (cred.fullId == keyshareCred || (!schemeManager.demo && cred.disallowDelete)) {
          repo.addMyIrmaCredential(cred);
        }
      });

      _instance = IrmaTestRepository._(repo, pref);
    }
    return _instance!;
  }

  Future<void> setUp({EnrollmentStatus enrollmentStatus = EnrollmentStatus.enrolled}) async {
    assert(enrollmentStatus != EnrollmentStatus.undetermined);
    final currentEnrollmentStatus =
        await inner.getEnrollmentStatus().firstWhere((s) => s != EnrollmentStatus.undetermined);
    if (currentEnrollmentStatus != EnrollmentStatus.unenrolled) {
      throw Exception('Test repository has not been teared down yet');
    }
    if (enrollmentStatus == EnrollmentStatus.enrolled) {
      inner.enroll(email: '', pin: '12345', language: 'en');
      await inner.getEnrollmentStatus().firstWhere((status) => status == EnrollmentStatus.enrolled);
      inner.lock();
    }

    await preferences.setAcceptedRootedRisk(true);
    inner.setDeveloperMode(true);
  }

  Future<void> tearDown() async {
    inner.dispatch(ClearAllDataEvent(), isBridgedEvent: true);
    await inner.getEvents().firstWhere((event) => event is! ClearAllDataEvent);
  }
}
