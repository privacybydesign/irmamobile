import 'package:irmamobile/src/models/clear_all_data_event.dart';

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

  Future<void> init() async {
    await preferences.setAcceptedRootedRisk(true);
    inner.setDeveloperMode(true);
  }

  Future<void> clean() async {
    inner.dispatch(ClearAllDataEvent(), isBridgedEvent: true);
    await inner.getEvents().firstWhere((event) => event is! ClearAllDataEvent);
  }
}
