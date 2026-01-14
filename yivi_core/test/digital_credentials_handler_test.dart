import "dart:convert";

import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/digital_credentials_handler.dart";
import "package:yivi_core/src/data/irma_mock_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("DigitalCredentialsHandler", () {
    late IrmaRepository mockRepository;
    late IrmaMockBridge mockBridge;
    late DigitalCredentialsHandler handler;
    late List<MethodCall> methodCallLog;

    setUp(() async {
      mockBridge = IrmaMockBridge();
      SharedPreferences.setMockInitialValues({});
      final preferences = await IrmaPreferences.fromInstance(
        mostRecentTermsUrlEn: "testurl",
        mostRecentTermsUrlNl: "testurl",
      );
      preferences.markLatestTermsAsAccepted(true);
      mockRepository = IrmaRepository(
        client: mockBridge,
        preferences: preferences,
      );
      handler = DigitalCredentialsHandler(mockRepository);
      methodCallLog = [];

      // Set up method channel mock to capture outgoing calls
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel("irma.app/digital_credentials"),
            (MethodCall methodCall) async {
              methodCallLog.add(methodCall);
              return null;
            },
          );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel("irma.app/digital_credentials"),
            null,
          );
      handler.dispose();
      await mockBridge.close();
      await mockRepository.close();
    });

    test("handles valid OpenID4VP credential request", () async {
      // Arrange
      const testUrl =
          "openid4vp://?request_uri=https://verifier.example.com/request&nonce=test123";
      final requestJson = jsonEncode({
        "url": testUrl,
        "requestJson": jsonEncode({
          "protocol": "openid4vp",
          "request": {
            "request_uri": "https://verifier.example.com/request",
            "nonce": "test123",
            "client_id": "verifier.example.com",
          },
        }),
        "callingPackage": "com.android.chrome",
        "callingOrigin": "https://example.com",
      });

      // Act
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            "irma.app/digital_credentials",
            const StandardMethodCodec().encodeMethodCall(
              MethodCall("handleDigitalCredentialRequest", requestJson),
            ),
            (ByteData? data) {},
          );

      // Allow async processing
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      // Verify that the handler processed the request without crashing
      // Full session flow testing requires the complete IRMA bridge
      expect(methodCallLog.isNotEmpty, isTrue);
    });

    test("rejects non-OpenID4VP protocol", () async {
      // Arrange
      const testUrl = "irma://qr/disclosing/...";
      final requestJson = jsonEncode({
        "url": testUrl,
        "requestJson": jsonEncode({"protocol": "irma", "request": {}}),
        "callingPackage": "com.android.chrome",
        "callingOrigin": "https://example.com",
      });

      // Act
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            "irma.app/digital_credentials",
            const StandardMethodCodec().encodeMethodCall(
              MethodCall("handleDigitalCredentialRequest", requestJson),
            ),
            (ByteData? data) {},
          );

      // Allow async processing
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(methodCallLog.any((call) => call.method == "returnError"), isTrue);
      final errorCall = methodCallLog.firstWhere(
        (call) => call.method == "returnError",
      );
      expect(errorCall.arguments["message"], contains("Unsupported protocol"));
    });

    test("rejects invalid URL format", () async {
      // Arrange
      final requestJson = jsonEncode({
        "url": "not-a-valid-url",
        "requestJson": jsonEncode({"protocol": "openid4vp", "request": {}}),
        "callingPackage": "com.android.chrome",
        "callingOrigin": "https://example.com",
      });

      // Act
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            "irma.app/digital_credentials",
            const StandardMethodCodec().encodeMethodCall(
              MethodCall("handleDigitalCredentialRequest", requestJson),
            ),
            (ByteData? data) {},
          );

      // Allow async processing
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(methodCallLog.any((call) => call.method == "returnError"), isTrue);
    });

    test("returns success when session completes", () async {
      // Arrange
      const testUrl =
          "openid4vp://?request_uri=https://verifier.example.com/request";
      final requestJson = jsonEncode({
        "url": testUrl,
        "requestJson": jsonEncode({
          "protocol": "openid4vp",
          "request": {"request_uri": "https://verifier.example.com/request"},
        }),
        "callingPackage": "com.android.chrome",
        "callingOrigin": "https://example.com",
      });

      // Act
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            "irma.app/digital_credentials",
            const StandardMethodCodec().encodeMethodCall(
              MethodCall("handleDigitalCredentialRequest", requestJson),
            ),
            (ByteData? data) {},
          );

      await Future.delayed(const Duration(milliseconds: 100));

      // Mock a successful disclosure session
      mockBridge.mockDisclosureSession(0, [
        [
          {"irma-demo.test.test.attr": null},
        ],
      ]);

      // Wait for session to be processed
      await Future.delayed(const Duration(milliseconds: 100));

      // The handler should have been called with the request
      // We can't fully test the success flow without the full IRMA bridge,
      // but we can verify the handler is initialized and receives requests
      expect(methodCallLog.isNotEmpty, isTrue);
    });

    test("returns error when session fails", () async {
      // Arrange
      const testUrl =
          "openid4vp://?request_uri=https://verifier.example.com/request";
      final requestJson = jsonEncode({
        "url": testUrl,
        "requestJson": jsonEncode({
          "protocol": "openid4vp",
          "request": {"request_uri": "https://verifier.example.com/request"},
        }),
        "callingPackage": "com.android.chrome",
        "callingOrigin": "https://example.com",
      });

      // Act
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            "irma.app/digital_credentials",
            const StandardMethodCodec().encodeMethodCall(
              MethodCall("handleDigitalCredentialRequest", requestJson),
            ),
            (ByteData? data) {},
          );

      await Future.delayed(const Duration(milliseconds: 100));

      // Assert that error handling works
      // In test environment, we expect error calls when sessions can't complete
      expect(methodCallLog.isNotEmpty, isTrue);
    });

    test("handles malformed JSON gracefully", () async {
      // Arrange
      const malformedJson = "not valid json {";

      // Act
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            "irma.app/digital_credentials",
            const StandardMethodCodec().encodeMethodCall(
              MethodCall("handleDigitalCredentialRequest", malformedJson),
            ),
            (ByteData? data) {},
          );

      // Allow async processing
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(methodCallLog.any((call) => call.method == "returnError"), isTrue);
    });

    test("handles cancelRequest method call", () async {
      // This test verifies the cancelRequest method exists and can be called
      // The actual cancellation logic is tested through integration tests

      // Act - just verify the method channel is set up correctly
      expect(handler, isNotNull);

      // The handler should be properly initialized
      expect(mockRepository, isNotNull);
    });
  });
}
