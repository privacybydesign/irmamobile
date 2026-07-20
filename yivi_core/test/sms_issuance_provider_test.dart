import "dart:convert";

import "package:altcha_lib/altcha_lib.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:yivi_core/src/providers/sms_issuance_provider.dart";

const _host = "https://issuer.example";
const _secret = "test-hmac-secret";

Future<Challenge> _issueChallenge() {
  return createChallenge(
    algorithm: "PBKDF2/SHA-256",
    cost: 200,
    counter: 21,
    deriveKey: deriveKey,
    hmacSignatureSecret: _secret,
    expiresAt: DateTime.now().add(const Duration(minutes: 10)),
  );
}

void main() {
  group("DefaultSmsIssuerApi.sendSms", () {
    test("fetches a challenge and attaches a verifiable altcha field", () async {
      final challenge = await _issueChallenge();
      String? sentBody;
      var challengeFetched = false;

      final client = MockClient((request) async {
        if (request.method == "GET" &&
            request.url.path == "/api/embedded/altcha-challenge") {
          challengeFetched = true;
          return http.Response(jsonEncode(challenge.toJson()), 200);
        }
        if (request.method == "POST" &&
            request.url.path == "/api/embedded/send") {
          sentBody = request.body;
          return http.Response("", 200);
        }
        return http.Response("unexpected ${request.url.path}", 500);
      });

      final api = DefaultSmsIssuerApi(host: _host, client: client);
      await api.sendSms(phoneNumber: "+31612345678", language: "en");

      expect(challengeFetched, isTrue);
      final body = jsonDecode(sentBody!) as Map<String, dynamic>;
      expect(body["phone"], "+31612345678");
      expect(body["altcha"], isA<String>());

      // The attached solution must verify against the original challenge.
      final submitted = Payload.fromJson(
        jsonDecode(utf8.decode(base64.decode(body["altcha"] as String)))
            as Map<String, dynamic>,
      );
      final result = await verifySolution(
        challenge: submitted.challenge,
        solution: submitted.solution,
        deriveKey: deriveKey,
        hmacSignatureSecret: _secret,
      );
      expect(result.verified, isTrue);
    });

    test("sends without a solution when no challenge is handed out", () async {
      String? sentBody;
      final client = MockClient((request) async {
        if (request.url.path == "/api/embedded/altcha-challenge") {
          return http.Response("not found", 404);
        }
        if (request.url.path == "/api/embedded/send") {
          sentBody = request.body;
          return http.Response("", 200);
        }
        return http.Response("unexpected", 500);
      });

      final api = DefaultSmsIssuerApi(host: _host, client: client);
      await api.sendSms(phoneNumber: "+31612345678", language: "en");

      final body = jsonDecode(sentBody!) as Map<String, dynamic>;
      expect(body.containsKey("altcha"), isFalse);
    });

    test("maps error:destination-not-allowed to a typed error", () async {
      final client = MockClient((request) async {
        if (request.url.path == "/api/embedded/altcha-challenge") {
          return http.Response("not found", 404);
        }
        return http.Response("error:destination-not-allowed", 400);
      });

      final api = DefaultSmsIssuerApi(host: _host, client: client);
      expect(
        () => api.sendSms(phoneNumber: "+99912345678", language: "en"),
        throwsA(isA<SmsIssuanceDestinationNotAllowedError>()),
      );
    });

    test("maps error:invalid-captcha to a captcha error", () async {
      final client = MockClient((request) async {
        if (request.url.path == "/api/embedded/altcha-challenge") {
          return http.Response("not found", 404);
        }
        return http.Response("error:invalid-captcha", 400);
      });

      final api = DefaultSmsIssuerApi(host: _host, client: client);
      expect(
        () => api.sendSms(phoneNumber: "+31612345678", language: "en"),
        throwsA(isA<SmsIssuanceCaptchaError>()),
      );
    });
  });
}
