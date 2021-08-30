import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/clear_all_data_event.dart';

// TODO Integrate this a bit more nicely
Future<void> setUpRepository() async {
  final repo = IrmaRepository(client: IrmaClientBridge());

  // Wait until the bridge responds as an indication that the bridge is fully active.
  await repo.bridge.events.first;
  await cleanRepository();

  // The scheme's KeyshareAttribute field is not fully accurate, so
  // we do a educated guess for additional myIRMA credentials.
  final config = await repo.getIrmaConfiguration().first;
  config.credentialTypes.forEach((_, cred) {
    final schemeManager = config.schemeManagers[cred.schemeManagerId];
    final keyshareAttr = schemeManager.keyshareAttribute?.split('.') ?? [];
    final keyshareCred = keyshareAttr.length == 4 ? keyshareAttr.sublist(0, 3).join('.') : '';
    if (cred.fullId == keyshareCred || !schemeManager.demo && cred.disallowDelete) {
      repo.addMyIrmaCredential(cred);
    }
  });
}

Future<void> cleanRepository() async {
  final repo = IrmaRepository.get();
  final prefs = IrmaPreferences.get();

  repo.dispatch(ClearAllDataEvent(), isBridgedEvent: true);

  await repo.getEvents().firstWhere((event) => event is! ClearAllDataEvent);

  await prefs.setAcceptedRootedRisk(true);
  repo.setDeveloperMode(true);
}
