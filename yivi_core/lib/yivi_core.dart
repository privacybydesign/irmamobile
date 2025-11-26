import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "app.dart";
import "src/data/irma_preferences.dart";
import "src/providers/irma_repository_provider.dart";
import "src/providers/mrz_processor_provider.dart";
import "src/providers/passport_issuer_provider.dart";
import "src/providers/preferences_provider.dart";
import "src/screens/home/home_screen.dart";
import "src/screens/notifications/bloc/notifications_bloc.dart";
import "src/sentry/sentry.dart";
import "src/util/navigation.dart";
import "src/util/security_context_binding.dart";
import "src/widgets/preferred_language_builder.dart";

export "src/models/mrz.dart";
export "src/providers/mrz_processor_provider.dart";

// The OcrProcessor is optional, when it's set to null the app won't include an mrz reader
// and the mrz will have to be entered manually by the user.
Future<void> runYiviApp({OcrProcessor? ocrProcessor}) async {
  FlutterError.onError = (FlutterErrorDetails details) {
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.empty,
    );
  };

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    final preferences = await IrmaPreferences.fromInstance(
      // when the terms have changed, these values should be updated in order to trigger a dialog in the app
      mostRecentTermsUrlNl: "https://yivi.app/terms_and_conditions_v3/",
      mostRecentTermsUrlEn: "https://yivi.app/en/terms_and_conditions_v3/",
    );

    await initSentry(preferences: preferences);
    SecurityContextBinding.ensureInitialized();

    const passportIssuanceError = String.fromEnvironment(
      "YIVI_ERROR_ON_PASSPORT_ISSUANCE",
    );
    if (passportIssuanceError.isNotEmpty) {
      debugPrint(
        "Configured to throw error on passport issuance: $passportIssuanceError",
      );
    }
    runApp(
      ProviderScope(
        overrides: [
          // we override this because otherwise we would have to deal with async/future providers everywhere
          // this is the recommended approach according to
          // https://riverpod.dev/docs/concepts/scopes#initialization-of-synchronous-provider-for-async-apis
          preferencesProvider.overrideWithValue(preferences),

          // passed in from the outside so apps are not required to depend on non-FOSS implementations
          ocrProcessorProvider.overrideWithValue(ocrProcessor),

          // can pass an environment variable to test with errors on passport issuance
          if (passportIssuanceError.isNotEmpty)
            passportIssuerProvider.overrideWithValue(
              ErrorThrowingPassportIssuer(
                errorToThrowOnIssuance: passportIssuanceError,
              ),
            ),
        ],
        child: YiviApp(),
      ),
    );
  }, (error, stackTrace) => reportError(error, stackTrace));
}

class YiviApp extends ConsumerWidget {
  final Locale? defaultLanguage;

  const YiviApp({super.key, this.defaultLanguage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(irmaRepositoryProvider);
    final notificationsBloc = NotificationsBloc(repo: repository);

    return TransitionStyleProvider(
      child: IrmaRepositoryProvider(
        repository: repository,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => notificationsBloc..add(Initialize()),
            ),
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
