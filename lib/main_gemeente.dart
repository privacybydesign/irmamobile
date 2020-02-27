import 'package:flutter/material.dart';
import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/widgets/credential_nudge.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  IrmaRepository(client: IrmaClientBridge());

  runApp(
    CredentialNudgeProvider(
      credentialNudge: CredentialNudge(
        fullCredentialTypeId: "pbdf.gemeente.personalData",
        showLaunchFailDialog: (_) {},
      ),
      child: const App(),
    ),
  );
}
