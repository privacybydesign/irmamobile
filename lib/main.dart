import 'package:flutter/material.dart';
import 'package:irmamobile/app.dart';
import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/widgets/credential_nudge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  IrmaRepository(client: IrmaClientBridge());

  runApp(
    CredentialNudgeProvider(
      credentialNudge: null,
      child: const App(),
    ),
  );
}
