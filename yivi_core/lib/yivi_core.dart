import "dart:async";
import "dart:io";

import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:pinput/pinput.dart";
import "package:vcmrtd/vcmrtd.dart" show ClientInfo;

import "app.dart";
import "src/data/irma_preferences.dart";
import "src/providers/face_verification_runner_provider.dart";
import "src/providers/irma_repository_provider.dart";
import "src/providers/ocr_processor_provider.dart";
import "src/providers/passport_issuer_provider.dart";
import "src/providers/preferences_provider.dart";
import "src/providers/qr_scanner_factory_provider.dart";
import "src/providers/schemaless_credentials_list_provider.dart";
import "src/providers/sms_issuance_provider.dart";
import "src/providers/store_review_provider.dart";
import "src/screens/home/home_screen.dart";
import "src/screens/notifications/bloc/notifications_bloc.dart";
import "src/sentry/sentry.dart";
import "src/util/navigation.dart";
import "src/util/security_context_binding.dart";
import "src/widgets/preferred_language_builder.dart";

// The method names a flavor keys its runners by; re-exported so the flavor
// entry points do not need their own vcmrtd dependency for one enum.
export "package:vcmrtd/vcmrtd.dart" show FaceVerificationMethod;

export "src/data/irma_repository.dart";
export "src/models/mrz.dart";
export "src/providers/email_issuance_provider.dart";
export "src/providers/face_verification_runner_provider.dart";
export "src/providers/ocr_processor_provider.dart";
export "src/providers/passport_issuer_provider.dart"
    show faceCaptureUrlProvider, faceVerificationConfigProvider;
export "src/providers/qr_scanner_factory_provider.dart";
export "src/providers/regula_face_service_provider.dart";
export "src/providers/sms_issuance_provider.dart";
export "src/providers/store_review_provider.dart" show StoreReviewService;
export "src/screens/embedded_issuance_flows/email/email_issuance_screen.dart";
export "src/screens/embedded_issuance_flows/sms/sms_issuance_screen.dart";

/// Builds the flavor's face verification runners, one per method it can run.
/// Takes a [Ref] because the FOSS Regula implementation's capture page is
/// derived from the passport issuer the session is talking to
/// ([faceCaptureUrlProvider]), which is only known at runtime.
typedef FaceVerificationRunnersBuilder =
    FaceVerificationRunners Function(Ref ref);

Future<void> runYiviApp({
  required QrScannerFactory qrScannerFactory,
  OcrProcessor? ocrProcessor,
  SmsRetriever? smsRetriever,
  FaceVerificationRunnersBuilder? faceVerificationRunners,

  /// The distribution flavor reported to the passport issuer with face
  /// verification attempts (e.g. `play`, `appstore`, `fdroid`). Together with
  /// the platform and the app version it labels the recordings that compare
  /// the face verification methods; `null` sends no such labels.
  String? clientFlavor,
  StoreReviewService? storeReviewService,
}) async {
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
        // Android 15+ enforces edge-to-edge, so bar colors are ignored;
        // icon brightness is what keeps the bars readable. App is light-only.
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // dark icons for light bg
        statusBarBrightness: Brightness.light, // iOS: light bg
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

    final clientInfo = clientFlavor == null
        ? null
        : ClientInfo(
            platform: Platform.isAndroid ? "android" : "ios",
            flavor: clientFlavor,
            appVersion: (await PackageInfo.fromPlatform()).version,
          );

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

          // passed in from the outside so apps are not required to depend on non-FOSS implementations
          smsRetrieverProvider.overrideWithValue(smsRetriever),

          // passed in from the outside so each app picks a scanner backend
          // appropriate to its distribution channel (ML Kit vs. zxing-cpp)
          qrScannerFactoryProvider.overrideWithValue(qrScannerFactory),

          // passed in from the outside so the FOSS build is not required to
          // depend on the Regula Face SDK or ship the Iris capture screen; the
          // map's keys are what the wallet declares it can run. Built from a
          // ref rather than a value so the FOSS capture page can follow the
          // session's passport issuer.
          faceVerificationRunnersProvider.overrideWith(
            (ref) => faceVerificationRunners?.call(ref) ?? const {},
          ),
          clientInfoProvider.overrideWithValue(clientInfo),

          // passed in from the outside so the proprietary in-app-review
          // dependency stays out of the FOSS build; null there disables the
          // whole review prompt
          storeReviewServiceProvider.overrideWithValue(storeReviewService),

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
  final Duration? idleLockThreshold;

  const YiviApp({super.key, this.defaultLanguage, this.idleLockThreshold});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(irmaRepositoryProvider);
    final notificationsBloc = NotificationsBloc(repo: repository);

    // Eagerly initialize the credential order controller so it starts
    // tracking credential changes before the data tab is first mounted.
    ref.read(schemalessCredentialOrderControllerProvider);

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
                idleLockThreshold: idleLockThreshold,
              );
            },
          ),
        ),
      ),
    );
  }
}
