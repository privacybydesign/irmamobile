import "dart:convert";

import "package:crypto/crypto.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/util/proof_of_work.dart";

void main() {
  group("leadingZeroBits", () {
    test("counts whole zero bytes", () {
      expect(leadingZeroBits([0x00, 0x00, 0xff]), 16);
    });

    test("counts partial leading zeros within a byte", () {
      expect(leadingZeroBits([0x0f]), 4);
      expect(leadingZeroBits([0x01]), 7);
      expect(leadingZeroBits([0x80]), 0);
    });

    test("is zero when the first bit is set", () {
      expect(leadingZeroBits([0xff, 0x00]), 0);
    });

    test("counts across byte boundaries", () {
      expect(leadingZeroBits([0x00, 0x0f]), 12);
    });
  });

  group("solveProofOfWork", () {
    test("difficulty 0 solves at nonce 0", () {
      final solution = solveProofOfWork(
        PowChallenge(
          challenge: "abc",
          difficulty: 0,
          expiry: 0,
          signature: "",
        ),
      );
      expect(solution.nonce, 0);
    });

    test("solution actually satisfies the difficulty", () {
      const challenge = "deadbeef";
      const difficulty = 12;
      final solution = solveProofOfWork(
        PowChallenge(
          challenge: challenge,
          difficulty: difficulty,
          expiry: 123,
          signature: "sig",
        ),
      );

      // Independently recompute the hash to confirm the nonce is valid.
      final digest = sha256
          .convert(utf8.encode("$challenge:${solution.nonce}"))
          .bytes;
      expect(leadingZeroBits(digest), greaterThanOrEqualTo(difficulty));
      expect(
        isValidPow(
          challenge: challenge,
          difficulty: difficulty,
          nonce: solution.nonce,
        ),
        isTrue,
      );
    });

    test("carries the challenge fields into the solution", () {
      final solution = solveProofOfWork(
        PowChallenge(
          challenge: "chal",
          difficulty: 4,
          expiry: 999,
          signature: "sig123",
        ),
      );
      expect(solution.challenge, "chal");
      expect(solution.difficulty, 4);
      expect(solution.expiry, 999);
      expect(solution.signature, "sig123");
      expect(solution.toJson(), {
        "challenge": "chal",
        "difficulty": 4,
        "expiry": 999,
        "signature": "sig123",
        "nonce": solution.nonce,
      });
    });
  });

  group("PowChallenge.tryParse", () {
    test("parses a well-formed challenge", () {
      final challenge = PowChallenge.tryParse({
        "challenge": "abc",
        "difficulty": 20,
        "expiry": 1700000000,
        "signature": "sig",
      });
      expect(challenge, isNotNull);
      expect(challenge!.challenge, "abc");
      expect(challenge.difficulty, 20);
      expect(challenge.expiry, 1700000000);
      expect(challenge.signature, "sig");
    });

    test("returns null when required fields are missing or malformed", () {
      expect(PowChallenge.tryParse(null), isNull);
      expect(PowChallenge.tryParse("not a map"), isNull);
      expect(PowChallenge.tryParse({"difficulty": 20}), isNull);
      expect(PowChallenge.tryParse({"challenge": "", "difficulty": 20}), isNull);
      expect(
        PowChallenge.tryParse({"challenge": "abc", "difficulty": "20"}),
        isNull,
      );
    });

    test("tolerates a missing expiry and signature", () {
      final challenge = PowChallenge.tryParse({
        "challenge": "abc",
        "difficulty": 8,
      });
      expect(challenge, isNotNull);
      expect(challenge!.expiry, 0);
      expect(challenge.signature, "");
    });
  });
}
