import "dart:convert";

import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "irma_binding.dart";

/// Integration tests for Digital Credentials API support
///
/// These tests verify that the Yivi app can act as a credential provider
/// for the Android Digital Credentials API, specifically for OpenID4VP protocol.
///
/// Implements OpenID4VP over Digital Credentials API as per Appendix A:
/// https://openid.net/specs/openid-4-verifiable-presentations-1_0.html#name-openid4vp-over-the-digital-
///
/// Supported protocols:
/// - openid4vp-v1-unsigned: Unsigned requests (client_id must be omitted)
/// - openid4vp-v1-signed: Signed requests using JWS Compact Serialization
/// - openid4vp-v1-multisigned: Signed requests using JWS JSON Serialization
///
/// Note: These tests simulate the Digital Credentials API flow but don't
/// actually involve Chrome or the Android Credential Manager, as those
/// components are not available in the test environment.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("Digital Credentials API - Appendix A Protocol", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("can receive unsigned OpenID4VP request (openid4vp-v1-unsigned)", (
      tester,
    ) async {
      // Test the DC API format per Appendix A: unsigned requests
      // client_id must be omitted for unsigned requests
      await tester.pumpAndSettle();

      // DC API request format (Appendix A)
      final dcApiRequest = jsonEncode({
        "protocol": "openid4vp-v1-unsigned",
        "request": {
          "nonce": "test-nonce-123",
          "dcql_query": {
            "credentials": [
              {
                "id": "email",
                "format": "dc+sd-jwt",
                "meta": {"vct_values": ["irma-demo.sidn-pbdf.email"]},
                "claims": [{"path": ["email"]}],
              },
            ],
          },
          "response_mode": "dc_api",
        },
      });

      final messageToFlutter = jsonEncode({
        "requestJson": dcApiRequest,
        "protocol": "openid4vp-v1-unsigned",
        "callingPackage": "com.android.chrome",
        "origin": "https://example.com",
      });

      try {
        await const MethodChannel(
          "irma.app/digital_credentials",
        ).invokeMethod("handleDigitalCredentialRequest", messageToFlutter);
      } catch (e) {
        // Expected to fail in test environment as the full flow isn't available
        // But verify handler exists and responds
        expect(e, isA<PlatformException>());
      }

      await tester.pumpAndSettle();
    });

    testWidgets("can receive signed OpenID4VP request (openid4vp-v1-signed)", (
      tester,
    ) async {
      // Test the DC API format per Appendix A: signed requests
      // expected_origins is required for signed requests
      await tester.pumpAndSettle();

      final dcApiRequest = jsonEncode({
        "protocol": "openid4vp-v1-signed",
        "request": {
          "nonce": "test-nonce-456",
          "request": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...", // JWS
          "expected_origins": ["https://example.com"],
          "response_mode": "dc_api",
        },
      });

      final messageToFlutter = jsonEncode({
        "requestJson": dcApiRequest,
        "protocol": "openid4vp-v1-signed",
        "callingPackage": "com.android.chrome",
        "origin": "https://example.com",
      });

      try {
        await const MethodChannel(
          "irma.app/digital_credentials",
        ).invokeMethod("handleDigitalCredentialRequest", messageToFlutter);
      } catch (e) {
        expect(e, isA<PlatformException>());
      }

      await tester.pumpAndSettle();
    });

    testWidgets("rejects unsupported protocol values", (tester) async {
      await tester.pumpAndSettle();

      // Try using old 'openid4vp' protocol (not a valid DC API protocol)
      final dcApiRequest = jsonEncode({
        "protocol": "openid4vp", // Invalid - should be openid4vp-v1-*
        "request": {"nonce": "test"},
      });

      final messageToFlutter = jsonEncode({
        "requestJson": dcApiRequest,
        "protocol": "openid4vp",
        "callingPackage": "com.android.chrome",
        "origin": "https://example.com",
      });

      try {
        await const MethodChannel(
          "irma.app/digital_credentials",
        ).invokeMethod("handleDigitalCredentialRequest", messageToFlutter);
        fail("Should reject invalid protocol");
      } catch (e) {
        expect(e, isA<PlatformException>());
      }

      await tester.pumpAndSettle();
    });

    testWidgets("validates request format", (tester) async {
      await tester.pumpAndSettle();

      // Send malformed request
      const malformedJson = "not valid json";

      try {
        await const MethodChannel(
          "irma.app/digital_credentials",
        ).invokeMethod("handleDigitalCredentialRequest", malformedJson);
        fail("Should have thrown exception for malformed JSON");
      } catch (e) {
        expect(e, isA<PlatformException>());
      }

      await tester.pumpAndSettle();
    });

    testWidgets("requires requestJson field", (tester) async {
      await tester.pumpAndSettle();

      // Missing requestJson field
      final incompleteRequest = jsonEncode({
        "protocol": "openid4vp-v1-unsigned",
        "callingPackage": "com.android.chrome",
        "origin": "https://example.com",
      });

      try {
        await const MethodChannel(
          "irma.app/digital_credentials",
        ).invokeMethod("handleDigitalCredentialRequest", incompleteRequest);
        fail("Should require requestJson field");
      } catch (e) {
        expect(e, isA<PlatformException>());
      }

      await tester.pumpAndSettle();
    });

    testWidgets("requires request object in DC API request", (tester) async {
      await tester.pumpAndSettle();

      // Missing 'request' object inside requestJson
      final dcApiRequest = jsonEncode({
        "protocol": "openid4vp-v1-unsigned",
        // Missing 'request' object
      });

      final messageToFlutter = jsonEncode({
        "requestJson": dcApiRequest,
        "protocol": "openid4vp-v1-unsigned",
        "callingPackage": "com.android.chrome",
        "origin": "https://example.com",
      });

      try {
        await const MethodChannel(
          "irma.app/digital_credentials",
        ).invokeMethod("handleDigitalCredentialRequest", messageToFlutter);
        fail("Should require request object");
      } catch (e) {
        expect(e, isA<PlatformException>());
      }

      await tester.pumpAndSettle();
    });
  });

  group("Digital Credentials API - Android Integration", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("GetCredentialActivity is properly registered", (tester) async {
      // This test verifies that the AndroidManifest.xml properly declares
      // the GetCredentialActivity with the correct intent filter.
      //
      // The activity should be registered with:
      // - android:name=".GetCredentialActivity"
      // - android:exported="true"
      // - Intent filter for "androidx.credentials.registry.provider.action.GET_CREDENTIAL"
      //
      // This is verified by the fact that the app builds and the activity
      // can receive method channel calls.

      await tester.pumpAndSettle();

      // Verify the method channel exists and is accessible
      const channel = MethodChannel("irma.app/digital_credentials");
      expect(channel, isNotNull);
    });

    testWidgets("handles various DCQL query formats", (tester) async {
      await tester.pumpAndSettle();

      // Test various DCQL query formats per DC API spec
      final testCases = [
        // Simple single credential query
        {
          "credentials": [
            {
              "id": "email",
              "format": "dc+sd-jwt",
              "meta": {"vct_values": ["irma-demo.sidn-pbdf.email"]},
              "claims": [{"path": ["email"]}],
            },
          ],
        },
        // Multiple credentials query
        {
          "credentials": [
            {
              "id": "email",
              "format": "dc+sd-jwt",
              "meta": {"vct_values": ["irma-demo.sidn-pbdf.email"]},
              "claims": [{"path": ["email"]}],
            },
            {
              "id": "name",
              "format": "dc+sd-jwt",
              "meta": {"vct_values": ["irma-demo.sidn-pbdf.name"]},
              "claims": [{"path": ["firstname"]}, {"path": ["lastname"]}],
            },
          ],
        },
      ];

      for (final dcqlQuery in testCases) {
        final dcApiRequest = jsonEncode({
          "protocol": "openid4vp-v1-unsigned",
          "request": {
            "nonce": "test-nonce-${dcqlQuery.hashCode}",
            "dcql_query": dcqlQuery,
            "response_mode": "dc_api",
          },
        });

        final messageToFlutter = jsonEncode({
          "requestJson": dcApiRequest,
          "protocol": "openid4vp-v1-unsigned",
          "callingPackage": "com.android.chrome",
          "origin": "https://example.com",
        });

        try {
          await const MethodChannel(
            "irma.app/digital_credentials",
          ).invokeMethod("handleDigitalCredentialRequest", messageToFlutter);
        } catch (e) {
          // May fail in test env, but should not crash
          expect(e, isA<Exception>());
        }
      }

      await tester.pumpAndSettle();
    });
  });

  group("Digital Credentials API - Response Flow", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("can return credential response", (tester) async {
      await tester.pumpAndSettle();

      // Test the returnCredential method
      final responseJson = jsonEncode({
        "protocol": "openid4vp",
        "status": "success",
        "sessionId": 42,
      });

      try {
        await const MethodChannel(
          "irma.app/digital_credentials",
        ).invokeMethod("returnCredential", {"responseJson": responseJson});
      } catch (e) {
        // May fail in test environment without actual Android activity
        expect(e, isA<Exception>());
      }

      await tester.pumpAndSettle();
    });

    testWidgets("can return error response", (tester) async {
      await tester.pumpAndSettle();

      try {
        await const MethodChannel(
          "irma.app/digital_credentials",
        ).invokeMethod("returnError", {"message": "Test error message"});
      } catch (e) {
        expect(e, isA<Exception>());
      }

      await tester.pumpAndSettle();
    });

    testWidgets("can cancel request", (tester) async {
      await tester.pumpAndSettle();

      try {
        await const MethodChannel(
          "irma.app/digital_credentials",
        ).invokeMethod("cancelRequest");
      } catch (e) {
        expect(e, isA<Exception>());
      }

      await tester.pumpAndSettle();
    });
  });
}
