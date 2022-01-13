// This code is not null safe yet.
// @dart=2.11

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_privacy_screen/flutter_privacy_screen.dart';
import 'package:irmamobile/app.dart';
import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/sentry/sentry.dart';
import 'package:irmamobile/src/widgets/credential_nudge.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    Zone.current.handleUncaughtError(details.exception, details.stack);
  };

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initSentry();
    IrmaRepository(client: IrmaClientBridge());

    if (!(await IrmaPreferences.get().getScreenshotsEnabled().first)) {
      await FlutterPrivacyScreen.enablePrivacyScreen();
    }

    runApp(const IrmaApp());
  }, (error, stackTrace) => reportError(error, stackTrace));
}

class IrmaApp extends StatelessWidget {
  final Locale forcedLocale;

  const IrmaApp({Key key, this.forcedLocale}) : super(key: key);

  @override
  Widget build(BuildContext context) => CredentialNudgeProvider(
        credentialNudge: null,
        child: App(
          forcedLocale: forcedLocale,
        ),
      );
}
