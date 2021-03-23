import 'package:flutter_driver/driver_extension.dart';
import 'package:irmamobile/app.dart';
import 'package:irmamobile/debug.dart';
import 'package:irmamobile/main.dart' as app;
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session.dart';

void main() {
  enableDebug = false;
  // This line enables the extension.
  enableFlutterDriverExtension(handler: (url) async {
    if (url != "") {
      AppState.fakeQRStream.add(SessionPointer.fromString(url));
    } else {
      IrmaPreferences.get().setAcceptedRootedRisk(true);
      final repo = IrmaRepository.get();
      repo.setDeveloperMode(true);
      // The scheme's KeyshareAttribute field is not fully accurate, so
      // we do a educated guess for additional myIRMA credentials.
      final config = await repo.getIrmaConfiguration().first;
      config.credentialTypes.forEach((_, cred) {
        final schemeManager = config.schemeManagers[cred.schemeManagerId];
        final keyshareAttr = schemeManager.keyshareAttribute?.split('.') ?? [];
        final keyshareCred = keyshareAttr.length == 4
            ? keyshareAttr.sublist(0, 3).join('.')
            : '';
        if (cred.fullId == keyshareCred ||
            !schemeManager.demo && cred.disallowDelete) {
          myIRMACredentials.add(cred.fullId);
        }
      });
    }
    return "";
  });

  // Call the `main()` function of the app, or call `runApp` with
  // any widget you are interested in testing.
  app.main();
}
