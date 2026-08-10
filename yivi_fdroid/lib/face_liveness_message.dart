import "dart:convert";

import "package:yivi_core/yivi_core.dart";

/// Outcome of a single message posted by the Yivi-hosted capture page over the
/// `YiviFace` JavaScript channel (see [FaceCaptureWebView]).
///
/// Exactly one of [result] / [failure] is non-null:
/// - [result] — the page reported `PROCESS_FINISHED`; the liveness verdict and
///   the (optional) transaction id to forward to the issuer.
/// - [failure] — the session was cancelled or errored; a human-readable reason
///   used for the thrown error and diagnostics.
class FaceCaptureMessage {
  final RegulaLivenessResult? result;
  final String? failure;

  const FaceCaptureMessage.completed(RegulaLivenessResult this.result)
    : failure = null;

  const FaceCaptureMessage.aborted(String this.failure) : result = null;
}

/// Parses one `YiviFace` channel [raw] message into a [FaceCaptureMessage],
/// mapping the capture page's outcomes to the same outcomes the native Regula
/// implementation produces so downstream issuance behaviour is identical:
///
/// - `{"status":"passed", "transactionId":...}` — liveness confirmed; the id
///   (which may be null → issuer skips the match, fail-open) is forwarded.
/// - `{"status":"failed", "transactionId":...}` — liveness not confirmed; the
///   id is still forwarded and the issuer decides.
/// - `{"status":"cancelled"}` / `{"status":"error", "message":...}` — the
///   session was aborted; the caller throws so the flow lands on the generic
///   issuance error screen, matching the native build.
/// - anything malformed or unrecognised is treated as an abort.
FaceCaptureMessage faceCaptureMessageFrom(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return const FaceCaptureMessage.aborted(
      "malformed message from capture page",
    );
  }
  if (decoded is! Map) {
    return const FaceCaptureMessage.aborted(
      "unexpected message from capture page",
    );
  }

  final transactionId = _asString(decoded["transactionId"]);
  switch (decoded["status"]) {
    case "passed":
      return FaceCaptureMessage.completed(
        RegulaLivenessResult(isLive: true, transactionId: transactionId),
      );
    case "failed":
      return FaceCaptureMessage.completed(
        RegulaLivenessResult(isLive: false, transactionId: transactionId),
      );
    case "cancelled":
      return const FaceCaptureMessage.aborted("cancelled");
    case "error":
      final message = _asString(decoded["message"]);
      return FaceCaptureMessage.aborted(
        message == null ? "capture page error" : "capture page error: $message",
      );
    case final status:
      return FaceCaptureMessage.aborted("unknown status: $status");
  }
}

/// Returns [value] as a non-empty [String], or null. Guards against the page
/// sending a non-string or empty transaction id.
String? _asString(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}
