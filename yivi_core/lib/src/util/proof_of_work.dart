import "dart:convert";

import "package:crypto/crypto.dart";

/// A proof-of-work challenge handed out by the SMS issuer.
///
/// The client has to find a [PowSolution] before the issuer will send an SMS.
/// The [challenge], [difficulty], [expiry] and [signature] fields are opaque to
/// the client: they are echoed back verbatim in the solution so the issuer can
/// verify its own signature statelessly. The client only needs [challenge] and
/// [difficulty] to compute a nonce.
class PowChallenge {
  final String challenge;
  final int difficulty;
  final int expiry;
  final String signature;

  PowChallenge({
    required this.challenge,
    required this.difficulty,
    required this.expiry,
    required this.signature,
  });

  /// Parses a challenge from the issuer's JSON response.
  ///
  /// Returns null when the response is not a proof-of-work challenge, so the
  /// caller can fall back to sending without a proof of work (for example when
  /// talking to an older issuer that does not yet hand out challenges).
  static PowChallenge? tryParse(dynamic json) {
    if (json is! Map) return null;
    final challenge = json["challenge"];
    final difficulty = json["difficulty"];
    if (challenge is! String || challenge.isEmpty || difficulty is! int) {
      return null;
    }
    return PowChallenge(
      challenge: challenge,
      difficulty: difficulty,
      expiry: json["expiry"] is int ? json["expiry"] as int : 0,
      signature: json["signature"] is String ? json["signature"] as String : "",
    );
  }
}

/// The nonce that solves a [PowChallenge], together with the challenge fields
/// needed by the issuer to verify it.
class PowSolution {
  final String challenge;
  final int difficulty;
  final int expiry;
  final String signature;
  final int nonce;

  PowSolution({
    required this.challenge,
    required this.difficulty,
    required this.expiry,
    required this.signature,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    "challenge": challenge,
    "difficulty": difficulty,
    "expiry": expiry,
    "signature": signature,
    "nonce": nonce,
  };
}

/// Counts the number of leading zero bits in [bytes].
int leadingZeroBits(List<int> bytes) {
  var count = 0;
  for (final b in bytes) {
    if (b == 0) {
      count += 8;
      continue;
    }
    for (var mask = 0x80; mask != 0; mask >>= 1) {
      if (b & mask != 0) return count;
      count++;
    }
    break;
  }
  return count;
}

/// Returns true when [nonce] solves [challenge] at the given [difficulty], i.e.
/// when SHA-256("challenge:nonce") starts with at least [difficulty] zero bits.
bool isValidPow({
  required String challenge,
  required int difficulty,
  required int nonce,
}) {
  final digest = sha256.convert(utf8.encode("$challenge:$nonce")).bytes;
  return leadingZeroBits(digest) >= difficulty;
}

/// Solves [challenge] by brute-forcing a nonce whose hash has at least
/// [challenge.difficulty] leading zero bits.
///
/// This is CPU-bound; run it off the UI thread (for example with
/// `Isolate.run`) so it never blocks rendering. Difficulty 0 solves
/// immediately, which lets an issuer effectively disable the check.
PowSolution solveProofOfWork(PowChallenge challenge) {
  var nonce = 0;
  while (!isValidPow(
    challenge: challenge.challenge,
    difficulty: challenge.difficulty,
    nonce: nonce,
  )) {
    nonce++;
  }
  return PowSolution(
    challenge: challenge.challenge,
    difficulty: challenge.difficulty,
    expiry: challenge.expiry,
    signature: challenge.signature,
    nonce: nonce,
  );
}
