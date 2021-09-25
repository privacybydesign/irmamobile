// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/widgets/credential_nudge.dart';
import 'package:irmamobile/src/widgets/irma_repository_provider.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = IrmaRepository(
    client: IrmaClientBridge(),
    preferences: await IrmaPreferences.fromInstance(),
  );

  runApp(
    IrmaRepositoryProvider(
      repository: repository,
      child: CredentialNudgeProvider(
        credentialNudge: CredentialNudge(
          fullCredentialTypeId: "pbdf.gemeente.personalData",
          showLaunchFailDialog: (_) {},
        ),
        child: const App(),
      ),
    ),
  );
}
