import "package:flutter/material.dart";
import "package:yivi_core/routing.dart";
import "package:yivi_core/yivi_core.dart";

import "face_capture_webview.dart";
import "face_liveness_message.dart";

/// FOSS [RegulaFaceService] for the F-Droid (Android/FOSS) flavor.
///
/// Instead of the proprietary `flutter_face_api` native SDK (which cannot ship
/// in an F-Droid build), this runs Regula's web Face SDK inside an embedded
/// [FaceCaptureWebView] that loads a Yivi-hosted capture page. The APK carries
/// only the BSD `webview_flutter` plugin and the page URL; all proprietary code
/// executes remotely (see #665).
///
/// It honours the same [RegulaFaceService] contract as the native
/// implementation, so the shared issuance flow (`withLivenessTransaction` →
/// issuer face match) is reused unchanged: on cancel or error it throws, so the
/// user lands on the generic issuance error screen, exactly as on the Play
/// Store / App Store build.
class RegulaWebFaceService implements RegulaFaceService {
  RegulaWebFaceService({
    Uri? captureUrl,
    @visibleForTesting Future<FaceCaptureMessage?> Function(Uri url)? present,
  }) : captureUrl = captureUrl ?? Uri.parse(defaultCaptureUrl),
       _present = present ?? _presentInWebView;

  /// The capture page, co-hosted on the Face SDK Web Service origin so the
  /// browser → service calls are same-origin (no CORS). Defaults to the same
  /// environment the native `RegulaFaceServiceImpl.defaultServiceUrl` points
  /// at; promote to the production host together with the native build for
  /// release.
  static const String defaultCaptureUrl =
      "https://faceapi.staging.yivi.app/capture";

  final Uri captureUrl;
  final Future<FaceCaptureMessage?> Function(Uri url) _present;

  /// The page self-initialises the web component, so there is nothing to do
  /// here; kept for parity with the native SDK's lifecycle.
  @override
  Future<void> initialize() async {}

  @override
  Future<RegulaLivenessResult> captureLiveness({String? languageCode}) async {
    final url = captureUrl.replace(
      queryParameters: {
        ...captureUrl.queryParameters,
        "lang": languageCode ?? "en",
      },
    );

    final message = await _present(url);
    if (message == null || message.result == null) {
      // Route dismissed without a completion (back/cancel), a page-load failure
      // or a component error: throw so the flow lands on the generic issuance
      // error screen, matching the native build.
      throw StateError(
        "Regula web liveness failed: ${message?.failure ?? 'cancelled'}",
      );
    }
    return message.result!;
  }

  /// Presents the capture page on the root navigator (the liveness step runs
  /// from within the NFC reading flow, which has no direct handle to a
  /// navigator of its own).
  static Future<FaceCaptureMessage?> _presentInWebView(Uri url) {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      throw StateError(
        "No navigator available to present the face capture screen.",
      );
    }
    return navigator.push<FaceCaptureMessage>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FaceCaptureWebView(captureUrl: url),
      ),
    );
  }
}
