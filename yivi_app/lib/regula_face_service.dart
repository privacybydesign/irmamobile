import "package:flutter/material.dart";
import "package:flutter_face_api/flutter_face_api.dart";
import "package:yivi_core/yivi_core.dart";

/// Yivi brand palette, mirrored from `IrmaThemeData` (yivi_core theme.dart) so
/// the Regula liveness UI matches the rest of the app. Kept as plain constants
/// because the Regula customization is applied at SDK-init time, without a
/// BuildContext.
class _Yivi {
  static const primary = Color(0xFFBA3354); // Yivi magenta (buttons/accents)
  static const textDark = Color(0xFF484747); // neutralExtraDark (titles)
  static const textMuted = Color(0xFF757375); // neutralDark (subtitles/hints)
  static const stroke = Color(0xFFCFE4EF); // tertiary (inactive stroke)
  static const background = Color(0xFFFFFFFF); // light
  static const onPrimary = Color(0xFFFFFFFF); // text/icon on magenta
}

/// Regula Face SDK-backed [RegulaFaceService] used by the Play Store / App Store
/// build.
///
/// Runs liveness against the Face API web service (which holds the Regula
/// license), so no license file ships in the app. The client only performs the
/// liveness session; the resulting transaction id is handed to the issuer,
/// which does the 1:1 match against the document chip portrait.
///
/// The liveness UI is themed to match Yivi (see [_applyYiviTheme]) and its
/// behaviour is tuned via the constructor flags below.
class RegulaFaceServiceImpl implements RegulaFaceService {
  RegulaFaceServiceImpl({
    this.serviceUrl = defaultServiceUrl,
    this.skipOnboarding = true,
    this.showCloseButton = false,
    this.livenessType = LivenessType.PASSIVE,
    FaceSDK? sdk,
  }) : _sdk = sdk ?? FaceSDK.instance;

  /// URL of the Regula Face API. Must be the same service the issuer uses for
  /// matching, so the liveness transaction id resolves on the backend.
  static const String defaultServiceUrl = "https://faceapi.staging.yivi.app";

  final String serviceUrl;

  /// When true, Regula's built-in "Time for a selfie" onboarding screen is
  /// skipped. Defaults to true: the app shows its own Yivi-themed
  /// FaceVerificationIntroScreen (with the privacy statement) before this runs.
  final bool skipOnboarding;

  /// When true, the liveness UI shows a close (X) button so the user can abort
  /// the session. Defaults to false: the user has already confirmed on the Yivi
  /// intro screen, so the camera screen has no close button.
  final bool showCloseButton;

  /// Liveness processing type. Defaults to [LivenessType.PASSIVE] (the user
  /// just looks at the camera; no active head-turn/blink challenges).
  final LivenessType livenessType;

  final FaceSDK _sdk;

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    // Route liveness processing to the licensed Face API backend. No local
    // license needed with the web-service model.
    _sdk.serviceUrl = serviceUrl;
    if (!await _sdk.isInitialized()) {
      final (success, error) = await _sdk.initialize();
      if (!success) {
        throw StateError(
          "Regula Face SDK initialization failed: ${error?.message ?? 'unknown error'}",
        );
      }
    }
    _applyYiviTheme();
    _initialized = true;
  }

  @override
  Future<RegulaLivenessResult> captureLiveness({String? languageCode}) async {
    await initialize();
    _applyLocalisation(languageCode);
    final liveness = await _sdk.startLiveness(config: _livenessConfig());
    if (liveness.error != null) {
      throw StateError("Regula liveness failed: ${liveness.error!.message}");
    }
    return RegulaLivenessResult(
      isLive: liveness.liveness == LivenessStatus.PASSED,
      transactionId: liveness.transactionId,
    );
  }

  /// Points the SDK at the app's active language and overrides the remaining
  /// Regula screens (camera hints, retry, processing, success) with Yivi's
  /// formal wording. The onboarding is not covered here — it is replaced by the
  /// app's own FaceVerificationIntroScreen. Keys are Regula's own string keys,
  /// extracted from the FaceSDK resource bundle.
  void _applyLocalisation(String? languageCode) {
    final lang = languageCode ?? "en";
    _sdk.locale = lang;
    _sdk.localizationDictionary = _regulaLabels[lang] ?? _regulaLabels["en"];
  }

  static const Map<String, Map<String, String>> _regulaLabels = {
    "en": {
      "livenessProcessing.title.processing": "Verifying…",
      "livenessDone.status": "Success",
      "livenessRetry.title.tryAgain": "Verification failed",
      "livenessRetry.action.retry": "Try again",
      "hint.lookStraight": "Look straight into the camera",
      "hint.moveCloser": "Move closer",
      "hint.moveAway": "Move a bit further away",
      "hint.stayStill": "Hold still",
      "hint.turnHead": "Turn your head slightly",
    },
    "nl": {
      "livenessProcessing.title.processing": "Bezig met controleren…",
      "livenessDone.status": "Gelukt",
      "livenessRetry.title.tryAgain": "Controle mislukt",
      "livenessRetry.action.retry": "Opnieuw proberen",
      "hint.lookStraight": "Kijk recht in de camera",
      "hint.moveCloser": "Kom dichterbij",
      "hint.moveAway": "Ga iets verder weg",
      "hint.stayStill": "Houd je hoofd stil",
      "hint.turnHead": "Draai je hoofd een beetje",
    },
    "de": {
      "livenessProcessing.title.processing": "Wird geprüft…",
      "livenessDone.status": "Erfolgreich",
      "livenessRetry.title.tryAgain": "Prüfung fehlgeschlagen",
      "livenessRetry.action.retry": "Erneut versuchen",
      "hint.lookStraight": "Blicken Sie direkt in die Kamera",
      "hint.moveCloser": "Näher kommen",
      "hint.moveAway": "Etwas weiter weg",
      "hint.stayStill": "Halten Sie den Kopf still",
      "hint.turnHead": "Drehen Sie den Kopf leicht",
    },
  };

  LivenessConfig _livenessConfig() => LivenessConfig(
    // Hide Regula's logo/watermark: this is a Yivi flow.
    copyright: false,
    closeButtonEnabled: showCloseButton,
    livenessType: livenessType,
    // The app is portrait-only.
    screenOrientation: const [ScreenOrientation.PORTRAIT],
    skipStep: skipOnboarding
        ? const [LivenessSkipStep.ONBOARDING_STEP]
        : const [],
  );

  /// Colours every Regula liveness screen (onboarding, camera, retry,
  /// processing, success) with the Yivi palette.
  void _applyYiviTheme() {
    _sdk.customization.colors = CustomizationColors()
      // Onboarding ("Time for a selfie") screen.
      ..onboardingScreenBackground = _Yivi.background
      ..onboardingScreenTitleLabelText = _Yivi.textDark
      ..onboardingScreenSubtitleLabelText = _Yivi.textMuted
      ..onboardingScreenMessageLabelsText = _Yivi.textDark
      ..onboardingScreenStartButtonBackground = _Yivi.primary
      ..onboardingScreenStartButtonTitle = _Yivi.onPrimary
      // Camera screen: face-frame stroke and hint labels.
      ..cameraScreenStrokeNormal = _Yivi.stroke
      ..cameraScreenStrokeActive = _Yivi.primary
      ..cameraScreenSectorTarget = _Yivi.stroke
      ..cameraScreenSectorActive = _Yivi.primary
      // Hint labels echo the intro tips: dark text on a light chip.
      ..cameraScreenFrontHintLabelBackground = _Yivi.background
      ..cameraScreenFrontHintLabelText = _Yivi.textDark
      ..cameraScreenBackHintLabelBackground = _Yivi.background
      ..cameraScreenBackHintLabelText = _Yivi.textDark
      ..cameraScreenLightToolbarTint = _Yivi.textDark
      ..cameraScreenDarkToolbarTint = _Yivi.onPrimary
      // Retry screen.
      ..retryScreenBackground = _Yivi.background
      ..retryScreenRetryButtonBackground = _Yivi.primary
      ..retryScreenRetryButtonTitle = _Yivi.onPrimary
      ..retryScreenTitleLabelText = _Yivi.textDark
      ..retryScreenSubtitleLabelText = _Yivi.textMuted
      ..retryScreenHintLabelsText = _Yivi.textDark
      // Processing + success screens.
      ..processingScreenBackground = _Yivi.background
      ..processingScreenProgress = _Yivi.primary
      ..processingScreenTitleLabel = _Yivi.textDark
      ..successScreenBackground = _Yivi.background;
  }
}
