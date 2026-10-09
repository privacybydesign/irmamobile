import "package:flutter_face_api/flutter_face_api.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi/regula_face_service.dart";

/// Stands in for the native SDK and keeps the config liveness was started with.
class _FakeFaceSdk implements FaceSDK {
  LivenessConfig? config;

  @override
  Customization customization = Customization();

  @override
  Future<bool> isInitialized() async => true;

  @override
  Future<LivenessResponse> startLiveness({
    LivenessConfig? config,
    LivenessNotificationCompletion? notificationCompletion,
    CameraSwitchCallback? cameraSwitchCallback,
  }) async {
    this.config = config;
    return LivenessResponse.fromJson({
      "liveness": LivenessStatus.PASSED.value,
      "transactionId": "transaction",
    })!;
  }

  // The service only sets serviceUrl, locale and localizationDictionary.
  @override
  void noSuchMethod(Invocation invocation) {}
}

void main() {
  test("lets the face check run in landscape as well as portrait", () async {
    final sdk = _FakeFaceSdk();
    final service = RegulaFaceServiceImpl(
      serviceUrl: "https://face.example.org",
      sdk: sdk,
    );

    final result = await service.captureLiveness(languageCode: "en");

    expect(result.isLive, isTrue);
    expect(sdk.config!.screenOrientation, [
      ScreenOrientation.PORTRAIT,
      ScreenOrientation.LANDSCAPE,
    ]);
  });
}
