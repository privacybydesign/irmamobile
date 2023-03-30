import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'src/data/irma_client_bridge.dart';
import 'src/data/irma_preferences.dart';
import 'src/data/irma_repository.dart';
import 'src/sentry/sentry.dart';
import 'src/util/security_context_binding.dart';
import 'src/widgets/irma_repository_provider.dart';
import 'src/widgets/preferred_language_builder.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    Zone.current.handleUncaughtError(details.exception, details.stack ?? StackTrace.empty);
  };

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final preferences = await IrmaPreferences.fromInstance();
    await initSentry(preferences: preferences);
    SecurityContextBinding.ensureInitialized();
    final repository = IrmaRepository(
      client: IrmaClientBridge(debugLogging: kDebugMode),
      preferences: preferences,
    );

    runApp(IrmaApp(repository: repository));
  }, (error, stackTrace) => reportError(error, stackTrace));
}

class IrmaApp extends StatelessWidget {
  final Locale? defaultLanguage;
  final IrmaRepository repository;

  const IrmaApp({
    Key? key,
    this.defaultLanguage,
    required this.repository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => IrmaRepositoryProvider(
        repository: repository,
        child: PreferredLocaleBuilder(builder: (context, preferredLocale) {
          Locale? appLocale;
          if (preferredLocale != null) {
            // The preferred locale is the locale that the user has selected in the settings
            // If it's not null it will override the system/default locale
            appLocale = preferredLocale;
          } else {
            // If there is a default locale prefer that one.
            // This is mainly used for testing purposes
            appLocale = defaultLanguage;
          }

          // If there is no preferred locale and no default locale,
          // appLocale will be null and the system locale will be used

          return App(
            irmaRepository: repository,
            forcedLocale: appLocale,
          );
        }),
      );
}
