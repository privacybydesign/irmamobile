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
      IrmaRepository.get().setDeveloperMode(true);
    }
    return "";
  });

  // Call the `main()` function of the app, or call `runApp` with
  // any widget you are interested in testing.
  app.main();
}
