import 'package:flutter_driver/driver_extension.dart';
import 'package:irmamobile/app.dart';
import 'package:irmamobile/main.dart' as app;
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/clear_all_data_event.dart';

void main() {
  // This line enables the extension.
  enableFlutterDriverExtension(handler: (msg) async {
    final repo = IrmaRepository.get();
    switch (msg) {
      case 'initialize':
        IrmaPreferences.get().setAcceptedRootedRisk(true);
        repo.setDeveloperMode(true);
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
        break;
        case 'reset':
          IrmaRepository.get().bridgedDispatch(
            ClearAllDataEvent(),
          );
          break;

      default:
        // In case we don't know the format, we assume it is a SessionPointer.
        repo.startSessionManually(SessionPointer.fromString(msg));
        break;
    }
    return "";
  });

  // Call the `main()` function of the app, or call `runApp` with
  // any widget you are interested in testing.
  app.main();
}
