import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'src/data/irma_preferences.dart';
import 'src/providers/irma_repository_provider.dart';
import 'src/providers/preferences_provider.dart';
import 'src/screens/home/home_screen.dart';
import 'src/screens/notifications/bloc/notifications_bloc.dart';
import 'src/sentry/sentry.dart';
import 'src/util/navigation.dart';
import 'src/util/security_context_binding.dart';
import 'src/widgets/preferred_language_builder.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    Zone.current.handleUncaughtError(details.exception, details.stack ?? StackTrace.empty);
  };

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final preferences = await IrmaPreferences.fromInstance(
      // when the terms have changed, these values should be updated in order to trigger a dialog in the app
      mostRecentTermsUrlNl: 'https://yivi.app/terms_and_conditions_v3/',
      mostRecentTermsUrlEn: 'https://yivi.app/en/terms_and_conditions_v3/',
    );

    await initSentry(preferences: preferences);
    SecurityContextBinding.ensureInitialized();

    runApp(
      ProviderScope(
        overrides: [
          // we override this because otherwise we would have to deal with async/future providers everywhere
          // this is the recommended approach according to
          // https://riverpod.dev/docs/concepts/scopes#initialization-of-synchronous-provider-for-async-apis
          preferencesProvider.overrideWithValue(preferences),
        ],
        child: IrmaApp(),
      ),
    );
  }, (error, stackTrace) => reportError(error, stackTrace));
}

class IrmaApp extends ConsumerWidget {
  final Locale? defaultLanguage;

  const IrmaApp({
    super.key,
    this.defaultLanguage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(irmaRepositoryProvider);
    final notificationsBloc = NotificationsBloc(repo: repository);

    return TransitionStyleProvider(
      child: IrmaRepositoryProvider(
        repository: repository,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => notificationsBloc..add(Initialize())),
            BlocProvider(create: (context) => HomeTabState()),
          ],
          child: PreferredLocaleBuilder(
            builder: (context, preferredLocale) {
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
                notificationsBloc: notificationsBloc,
              );
            },
          ),
        ),
      ),
    );
  }
}
