import "dart:convert";

import "package:altcha_lib/altcha_lib.dart";

/// The proof-of-work algorithm the issuer pins its challenges to. Anything else
/// is rejected client-side so an old or misconfigured issuer cannot make the
/// app burn CPU on a challenge it can never solve.
const _pinnedAlgorithm = "PBKDF2/SHA-256";

/// Parses an ALTCHA v2 challenge from the issuer's JSON response.
///
/// Returns null when the response is not a well-formed challenge, so the caller
/// can fall back to sending without a solution (for example when talking to an
/// issuer that does not yet hand out challenges, or one that serves an
/// unrelated body for the challenge path).
Challenge? tryParseAltchaChallenge(dynamic json) {
  if (json is! Map<String, dynamic>) return null;
  try {
    return Challenge.fromJson(json);
  } catch (_) {
    return null;
  }
}

/// Solves an ALTCHA [challenge] off the main thread and returns the base64
/// payload to attach to the send request as the `altcha` field.
///
/// Returns null when the challenge cannot be solved (an unexpected algorithm,
/// or a timeout), so the caller can fall back to sending without a solution.
/// Solving runs on background isolates via [solveChallengeIsolates] so it never
/// blocks the UI thread.
Future<String?> solveAltchaChallenge(
  Challenge challenge, {
  int concurrency = 4,
}) async {
  // The algorithm lives inside the server-signed challenge params, so the
  // server cannot be tricked into naming a different one, but a stale server
  // could. Bail early rather than run PBKDF2 against a challenge whose derived
  // key we could never match.
  if (challenge.parameters.algorithm.toUpperCase() !=
      _pinnedAlgorithm.toUpperCase()) {
    return null;
  }

  final Solution? solution;
  try {
    solution = await solveChallengeIsolates(
      challenge: challenge,
      deriveKey: deriveKey,
      concurrency: concurrency,
    );
  } catch (_) {
    return null;
  }
  if (solution == null) return null;

  return base64.encode(
    utf8.encode(
      jsonEncode({
        "challenge": challenge.toJson(),
        "solution": solution.toJson(),
      }),
    ),
  );
}
