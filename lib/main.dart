// This code is not null safe yet.
// @dart=2.11

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:irmamobile/app.dart';
import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/sentry/sentry.dart';
import 'package:irmamobile/src/widgets/irma_repository_provider.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    Zone.current.handleUncaughtError(details.exception, details.stack);
  };

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final preferences = await IrmaPreferences.fromInstance();
    await initSentry(preferences: preferences);
    final repository = IrmaRepository(
      client: IrmaClientBridge(debugLogging: kDebugMode),
      preferences: preferences,
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
        child: App(
          forcedLocale: forcedLocale,
        ),
      );
}
