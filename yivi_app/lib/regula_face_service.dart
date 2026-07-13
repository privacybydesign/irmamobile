import "package:flutter_face_api/flutter_face_api.dart";
import "package:yivi_core/yivi_core.dart";

/// Regula Face SDK-backed [RegulaFaceService] used by the Play Store / App Store
/// build.
///
/// Runs liveness against the Face API web service (which holds the Regula
/// license), so no license file ships in the app. The client only performs the
/// liveness session; the resulting transaction id is handed to the issuer,
/// which does the 1:1 match against the document chip portrait.
class RegulaFaceServiceImpl implements RegulaFaceService {
  RegulaFaceServiceImpl({this.serviceUrl = defaultServiceUrl, FaceSDK? sdk})
    : _sdk = sdk ?? FaceSDK.instance;

  /// URL of the Regula Face API. Must be the same service the issuer uses for
  /// matching, so the liveness transaction id resolves on the backend.
  static const String defaultServiceUrl = "https://faceapi.staging.yivi.app";

  final String serviceUrl;
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
    _initialized = true;
  }

  @override
  Future<RegulaLivenessResult> captureLiveness() async {
    await initialize();
    final liveness = await _sdk.startLiveness();
    if (liveness.error != null) {
      throw StateError("Regula liveness failed: ${liveness.error!.message}");
    }
    return RegulaLivenessResult(
      isLive: liveness.liveness == LivenessStatus.PASSED,
      transactionId: liveness.transactionId,
    );
  }
}
