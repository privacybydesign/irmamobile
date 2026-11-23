import "../../models/session.dart";

/// Who caused a session error, as far as the error itself can tell.
///
/// Most errors can't be pinned on one side: a 500 from a server, a broken
/// response or an unknown credential type can be the app's fault or the
/// organisation's. Those are [unknown], and Yivi support looks first. Only
/// errors that can only come from the organisation are [organisation], so
/// users are never sent to an organisation for a problem in Yivi.
enum SessionErrorCause {
  /// Yivi's own code or servers (keyshare, scheme, cryptography).
  yivi,

  /// Only the organisation's request or server can cause this.
  organisation,

  /// Could be either side.
  unknown,

  /// The session timed out or was already used. Starting again fixes it.
  expired,
}

/// Errors raised by Yivi's own code or servers.
const _yiviErrorTypes = {
  "keyshare",
  "keyshareUnenrolled",
  "crypto",
  "panic",
  "serialization",
  "randomblind",
  "configurationDownload",
  "unknownSchemeManager",
  "invalidSchemeManager",
};

/// Errors only an organisation can cause.
const _organisationErrorTypes = {
  // The organisation's server does not use https.
  "https",
  // An issuer asked to issue a credential without a required attribute.
  "requiredAttributeMissing",
};

/// Remote errors only an organisation's server can return.
const _organisationRemoteErrors = {
  // The organisation's server failed to start the session that follows.
  "NEXT_SESSION",
};

const _expiredRemoteErrors = {"SESSION_UNKNOWN", "UNEXPECTED_REQUEST"};

SessionErrorCause sessionErrorCause(SessionError? error) {
  if (error == null) return SessionErrorCause.unknown;

  final remote = error.remoteError?.errorName;
  if (_expiredRemoteErrors.contains(remote)) return SessionErrorCause.expired;
  if (_organisationRemoteErrors.contains(remote)) {
    return SessionErrorCause.organisation;
  }
  if (_organisationErrorTypes.contains(error.errorType)) {
    return SessionErrorCause.organisation;
  }
  if (_yiviErrorTypes.contains(error.errorType)) return SessionErrorCause.yivi;
  return SessionErrorCause.unknown;
}

/// The code to quote to an organisation's helpdesk: the remote error name
/// when the server gave one, otherwise the error type.
String? sessionErrorCode(SessionError? error) {
  final remote = error?.remoteError?.errorName;
  if (remote != null && remote.isNotEmpty) return remote;
  final type = error?.errorType;
  return type == null || type.isEmpty ? null : type;
}
