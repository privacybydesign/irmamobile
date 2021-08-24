import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_privacy_screen/flutter_privacy_screen.dart';
import 'package:irmamobile/app.dart';
import 'package:irmamobile/src/data/irma_client_bridge.dart';
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

    await FlutterPrivacyScreen.enablePrivacyScreen();

    runApp(
      const CredentialNudgeProvider(
        credentialNudge: null,
        child: App(),
      ),
    );
  }, (error, stackTrace) => reportError(error, stackTrace));
}
