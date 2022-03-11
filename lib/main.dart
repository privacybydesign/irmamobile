// This code is not null safe yet.
// @dart=2.11

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:irmamobile/app.dart';
import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/sentry/sentry.dart';
import 'package:irmamobile/src/widgets/credential_nudge.dart';
import 'package:irmamobile/src/widgets/irma_repository_provider.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    Zone.current.handleUncaughtError(details.exception, details.stack);
  };

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initSentry();
    final repository = IrmaRepository(
      client: IrmaClientBridge(),
      preferences: await IrmaPreferences.fromInstance(),
    );

    runApp(IrmaApp(repository: repository));
  }, (error, stackTrace) => reportError(error, stackTrace));
}

class IrmaApp extends StatelessWidget {
  final Locale forcedLocale;
  final IrmaRepository repository;

  const IrmaApp({Key key, this.forcedLocale, this.repository}) : super(key: key);

  @override
  Widget build(BuildContext context) => IrmaRepositoryProvider(
        repository: repository,
        child: CredentialNudgeProvider(
          credentialNudge: null,
          child: App(
            forcedLocale: forcedLocale,
          ),
        ),
      );
}
