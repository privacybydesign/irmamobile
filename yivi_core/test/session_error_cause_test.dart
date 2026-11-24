import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/screens/error/session_error_cause.dart";

SessionError _error(String type, {String? remote}) => SessionError(
  errorType: type,
  info: "",
  remoteError: remote == null ? null : RemoteError(errorName: remote),
);

void main() {
  group("sessionErrorCause", () {
    test("Yivi's own code and servers", () {
      for (final type in [
        "keyshare",
        "keyshareUnenrolled",
        "crypto",
        "panic",
        "serialization",
        "randomblind",
        "configurationDownload",
        "unknownSchemeManager",
        "invalidSchemeManager",
      ]) {
        expect(
          sessionErrorCause(_error(type)),
          SessionErrorCause.yivi,
          reason: type,
        );
      }
    });

    test("only the organisation can cause these", () {
      expect(
        sessionErrorCause(_error("api", remote: "NEXT_SESSION")),
        SessionErrorCause.organisation,
      );
      expect(
        sessionErrorCause(_error("https")),
        SessionErrorCause.organisation,
      );
      expect(
        sessionErrorCause(_error("requiredAttributeMissing")),
        SessionErrorCause.organisation,
      );
    });

    test("the user can start again", () {
      for (final remote in ["SESSION_UNKNOWN", "UNEXPECTED_REQUEST"]) {
        expect(
          sessionErrorCause(_error("api", remote: remote)),
          SessionErrorCause.expired,
          reason: remote,
        );
      }
    });

    // The user's concern: when the error can't tell, never default to
    // sending people to the organisation.
    test("anything ambiguous is unknown, so Yivi looks first", () {
      for (final (type, remote) in [
        ("serverResponse", null),
        ("api", "INTERNAL_ERROR"),
        ("api", "EXCEPTION"),
        ("api", "INVALID_PROOFS"),
        ("api", "UNKNOWN_PUBLIC_KEY"),
        ("unknownIdentifier", null),
        ("invalidRequest", null),
        ("revocation", null),
        ("rejected", null),
        ("clientReturnUrl", null),
        ("unknown", null),
        ("", null),
      ]) {
        expect(
          sessionErrorCause(_error(type, remote: remote)),
          SessionErrorCause.unknown,
          reason: "$type $remote",
        );
      }
      expect(sessionErrorCause(null), SessionErrorCause.unknown);
    });

    test("a keyshare error with a server error stays Yivi's", () {
      expect(
        sessionErrorCause(_error("keyshare", remote: "INTERNAL_ERROR")),
        SessionErrorCause.yivi,
      );
    });
  });

  group("sessionErrorCode", () {
    test("prefers the remote error name", () {
      expect(
        sessionErrorCode(_error("api", remote: "NEXT_SESSION")),
        "NEXT_SESSION",
      );
    });

    test("falls back to the error type", () {
      expect(sessionErrorCode(_error("https")), "https");
      expect(sessionErrorCode(_error("api", remote: "")), "api");
    });

    test("is null without an error", () {
      expect(sessionErrorCode(null), isNull);
      expect(sessionErrorCode(_error("")), isNull);
    });
  });
}
