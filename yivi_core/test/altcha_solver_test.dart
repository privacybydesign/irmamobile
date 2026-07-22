import "dart:convert";

import "package:altcha_lib/altcha_lib.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/util/altcha_solver.dart";

const _secret = "test-hmac-secret";

/// Mints a challenge exactly the way the issuer does (ALTCHA v2, PBKDF2/SHA-256,
/// HMAC-signed), with [counter] pre-selected so solving is fast and
/// deterministic.
Future<Challenge> _issueChallenge({
  int counter = 37,
  String algorithm = "PBKDF2/SHA-256",
  int cost = 200,
}) {
  return createChallenge(
    algorithm: algorithm,
    cost: cost,
    counter: counter,
    deriveKey: deriveKey,
    hmacSignatureSecret: _secret,
    expiresAt: DateTime.now().add(const Duration(minutes: 10)),
  );
}

void main() {
  group("tryParseAltchaChallenge", () {
    test("returns null for non-map input", () {
      expect(tryParseAltchaChallenge(null), isNull);
      expect(tryParseAltchaChallenge("not a map"), isNull);
      expect(tryParseAltchaChallenge(42), isNull);
    });

    test("returns null for a malformed challenge", () {
      expect(tryParseAltchaChallenge({"parameters": {}}), isNull);
      expect(tryParseAltchaChallenge({"signature": "abc"}), isNull);
    });

    test("parses a well-formed challenge round-tripped through JSON", () async {
      final challenge = await _issueChallenge();
      // The provider decodes the HTTP body, so parse from decoded JSON.
      final parsed = tryParseAltchaChallenge(
        jsonDecode(jsonEncode(challenge.toJson())),
      );
      expect(parsed, isNotNull);
      expect(parsed!.parameters.algorithm, "PBKDF2/SHA-256");
      expect(parsed.signature, challenge.signature);
    });
  });

  group("solveAltchaChallenge", () {
    test("produces a payload the issuer verifies", () async {
      final challenge = await _issueChallenge();

      final payload = await solveAltchaChallenge(challenge, concurrency: 1);
      expect(payload, isNotNull);

      // The server decodes base64(JSON) into a {challenge, solution} payload.
      final decoded =
          jsonDecode(utf8.decode(base64.decode(payload!)))
              as Map<String, dynamic>;
      final submitted = Payload.fromJson(decoded);

      final result = await verifySolution(
        challenge: submitted.challenge,
        solution: submitted.solution,
        deriveKey: deriveKey,
        hmacSignatureSecret: _secret,
      );
      expect(result.verified, isTrue);
    });

    test("a tampered solution counter fails verification", () async {
      final challenge = await _issueChallenge();
      final payload = await solveAltchaChallenge(challenge, concurrency: 1);
      final decoded =
          jsonDecode(utf8.decode(base64.decode(payload!)))
              as Map<String, dynamic>;
      final submitted = Payload.fromJson(decoded);

      final result = await verifySolution(
        challenge: submitted.challenge,
        // Solve found the real counter; a different one is not a solution.
        solution: Solution(
          counter: submitted.solution.counter + 1,
          derivedKey: submitted.solution.derivedKey,
        ),
        deriveKey: deriveKey,
        hmacSignatureSecret: _secret,
      );
      expect(result.verified, isFalse);
    });

    test("returns null for a non-PBKDF2 algorithm", () async {
      // Build a syntactically valid challenge that names an unsupported
      // algorithm; the solver must refuse it rather than burn CPU.
      final challenge = Challenge(
        parameters: ChallengeParameters(
          algorithm: "ARGON2ID",
          nonce: "00",
          salt: "00",
          cost: 1,
          keyLength: 32,
          keyPrefix: "00",
        ),
        signature: "irrelevant",
      );
      expect(await solveAltchaChallenge(challenge, concurrency: 1), isNull);
    });
  });
}
