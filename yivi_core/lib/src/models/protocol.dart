enum Protocol { irma, openid4vp, openid4vci, iso18013_5, unknown }

String? protocolToStringOptional(Protocol? protocol) {
  if (protocol == null) {
    return null;
  }
  return protocolToString(protocol);
}

String protocolToString(Protocol protocol) {
  return switch (protocol) {
    Protocol.irma => "irma",
    Protocol.openid4vp => "openid4vp",
    Protocol.openid4vci => "openid4vci",
    Protocol.iso18013_5 => "iso18013-5",
    Protocol.unknown => "unknown",
  };
}

/// Parses a protocol, yielding [Protocol.unknown] for one this build does not
/// recognise rather than throwing.
///
/// The fallback is the point, and it is not defensive programming for its own
/// sake. Protocols are written into the activity log and read back long
/// afterwards, so a stored entry can name one added after the build reading it.
/// This parse runs inside the decoding of a whole PAGE of log entries, so
/// throwing does not hide one row — it aborts the entire LogsEvent and the user
/// sees an empty activity list where their history used to be. That is exactly
/// what one org-iso-mdoc disclosure did.
///
/// Unknown rather than a plausible substitute: reporting it as openid4vp would
/// trade a missing label for a wrong one, and a log the user cannot trust to be
/// accurate is worth less than a log that admits what it does not know.
Protocol stringToProtocol(String protocol) {
  return switch (protocol) {
    "irma" => Protocol.irma,
    "openid4vp" => Protocol.openid4vp,
    "openid4vci" => Protocol.openid4vci,
    "iso18013-5" => Protocol.iso18013_5,
    _ => Protocol.unknown,
  };
}
