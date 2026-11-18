import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "protocol.dart";

part "email_code_pointer.dart";
part "session.g.dart";

class MissingPointer implements Exception {
  final String details;

  MissingPointer({required this.details});

  String errorMessage() {
    return "URI does not contain a session pointer: $details";
  }

  @override
  String toString() {
    return "MissingPointer(details: ${errorMessage()})";
  }
}

const universalLinkHosts = {"open.yivi.app", "open.staging.yivi.app"};

/// What a link or QR code points to: a new session ([SessionPointer]) or
/// the code from a verification e-mail ([EmailCodePointer]).
sealed class Pointer {
  factory Pointer.fromString(String content) {
    // OAuth `redirect_uri` for OpenID4VCI auth-code / pre-auth-code flows.
    // Default to production; if the inbound URL is a universal link on a
    // recognized host (notably the staging host), derive the callback URI
    // from that host so staging issuers redirect back to the staging
    // bounce page. The wallet ships this to the Go core per-session.
    String openid4vciRedirectUri = "https://open.yivi.app/-/auth-callback";

    final parsed = Uri.tryParse(content);
    if (parsed != null &&
        parsed.scheme == "https" &&
        universalLinkHosts.contains(parsed.host)) {
      openid4vciRedirectUri = "https://${parsed.host}/-/auth-callback";
      if (parsed.path == "/-/openid4vp" || parsed.path == "/-/openid4vp/") {
        content = "openid4vp://?${parsed.query}";
      } else if (parsed.path == "/-/openid-credential-offer" ||
          parsed.path == "/-/openid-credential-offer/") {
        content = "openid-credential-offer://?${parsed.query}";
      }
    }

    if (content.startsWith("eudi-openid4vp://") ||
        content.startsWith("openid4vp://")) {
      final uri = Uri.parse(content);
      final clientId = uri.queryParameters["client_id"];
      if (clientId == null) {
        throw MissingPointer(
          details:
              'expected "client_id" to be present in query parameters, but it wasn\'t',
        );
      }
      return SessionPointer(
        u: content,
        irmaqr: "disclosing",
        protocol: Protocol.openid4vp,
      );
    }

    if (content.startsWith("openid-credential-offer://")) {
      final uri = Uri.parse(content);
      final credentialOfferUri = uri.queryParameters["credential_offer_uri"];
      final credentialOffer = uri.queryParameters["credential_offer"];
      if (credentialOfferUri == null && credentialOffer == null) {
        throw MissingPointer(
          details:
              'expected "credential_offer" or "credential_offer_uri" to be present in query parameters, but it wasn\'t',
        );
      }
      return SessionPointer(
        u: content,
        irmaqr: "issuing",
        protocol: Protocol.openid4vci,
        openid4vciRedirectUri: openid4vciRedirectUri,
      );
    }

    // Use lookahead and lookbehinds to block out the non-JSON part of the string
    final regexps = [
      RegExp("(?<=^irma://qr/json/).*"),
      RegExp("(?<=^cardemu://qr/json/).*"),
      RegExp("(?<=^intent://qr/json/).*(?=#)"),
      RegExp("(?<=^https://irma.app/-/session#).*"),
      RegExp("(?<=^https://irma.app/-pilot/session#).*"),
      RegExp("(?<=^https://open.yivi.app/-/session#).*"),
      RegExp("(?<=^https://open.yivi.app/-pilot/session#).*"),
      RegExp("(?<=^https://open.staging.yivi.app/-/session#).*"),
      RegExp("(?<=^https://open.staging.yivi.app/-pilot/session#).*"),
      RegExp(".*", multiLine: true, dotAll: true),
    ];

    final Map<String, dynamic> json;
    try {
      String? jsonString;
      for (final regex in regexps) {
        final match = regex.stringMatch(content);
        if (match != null && match.isNotEmpty) {
          jsonString = Uri.decodeComponent(match);
          break;
        }
      }

      if (jsonString == null) {
        throw MissingPointer(details: "unsupported uri scheme");
      }

      json = jsonDecode(jsonString) as Map<String, dynamic>;

      return SessionPointer.fromJson(json);
    } catch (e) {
      throw MissingPointer(details: e.toString());
    }
  }
}

// parsing session pointer directly from json only happens for irma sessions
Protocol _protocolFromJsonAlwaysIrma(String? protocol) {
  return Protocol.irma;
}

// Web QR payloads send camelCase `continueOnSecondDevice`; the irmago bridge
// uses snake `continue_on_second_device` (snake wins when both are present).
// Read-side fallback only — don't unify via @JsonKey(name:): that would flip
// toJson to camelCase and break Go's round-trip.
Object? _readContinueOnSecondDevice(Map<dynamic, dynamic> json, String key) =>
    json[key] ?? json["continueOnSecondDevice"];

/// A pointer that refers to a new IRMA session.
@JsonSerializable(fieldRename: FieldRename.snake)
final class SessionPointer implements Pointer {
  @JsonKey(name: "u", required: true)
  final String u;

  @JsonKey(name: "irmaqr", required: true)
  final String irmaqr;

  @JsonKey(
    name: "protocol",
    required: false,
    toJson: protocolToString,
    fromJson: _protocolFromJsonAlwaysIrma,
  )
  final Protocol protocol;

  /// Whether the session should be continued on the mobile device,
  /// or on the device which has displayed a QR code.
  /// Field is not always specified in QRs; the app sets it where it knows
  /// better, through [copyWith].
  @JsonKey(readValue: _readContinueOnSecondDevice)
  final bool continueOnSecondDevice;

  /// OAuth `redirect_uri` for OpenID4VCI auth-code / pre-auth-code flows.
  /// Populated only for [Protocol.openid4vci] pointers; derived from the
  /// inbound universal link's host so staging-host offers redirect to the
  /// staging bounce page (`https://open.staging.yivi.app/-/auth-callback`).
  /// Forwarded as `openid4vci_redirect_uri` to the Go core's session request.
  @JsonKey(name: "openid4vci_redirect_uri", includeIfNull: false)
  final String? openid4vciRedirectUri;

  SessionPointer({
    required this.u,
    required this.irmaqr,
    required this.protocol,
    this.continueOnSecondDevice = false,
    this.openid4vciRedirectUri,
  });

  SessionPointer copyWith({bool? continueOnSecondDevice}) => SessionPointer(
    u: u,
    irmaqr: irmaqr,
    protocol: protocol,
    continueOnSecondDevice:
        continueOnSecondDevice ?? this.continueOnSecondDevice,
    openid4vciRedirectUri: openid4vciRedirectUri,
  );

  factory SessionPointer.fromJson(Map<String, dynamic> json) =>
      _$SessionPointerFromJson(json);
  Map<String, dynamic> toJson() => _$SessionPointerToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SessionError {
  SessionError({
    required this.errorType,
    required this.info,
    this.wrappedError = "",
    this.stack = "",
    this.remoteStatus,
    this.remoteError,
  });

  final String errorType;

  final String wrappedError;

  final String info;

  final String stack;

  final int? remoteStatus;

  final RemoteError? remoteError;

  bool get reportable => !["https", "notSupported"].contains(errorType);

  factory SessionError.fromJson(Map<String, dynamic> json) {
    // Handle both snake_case (from bridge sessionError wrapper) and
    // PascalCase (from Go's default marshaling of irma.SessionError).
    final normalized = <String, dynamic>{
      "error_type": json["error_type"] ?? json["ErrorType"] ?? "",
      "info": json["info"] ?? json["Info"] ?? "",
      "wrapped_error": json["wrapped_error"] ?? json["WrappedError"] ?? "",
      "stack": json["stack"] ?? json["Stack"] ?? "",
      "remote_status": json["remote_status"] ?? json["RemoteStatus"],
      "remote_error": json["remote_error"] ?? json["RemoteError"],
    };
    return _$SessionErrorFromJson(normalized);
  }
  Map<String, dynamic> toJson() => _$SessionErrorToJson(this);

  @override
  String toString() => [
    if (remoteStatus != null && remoteStatus! > 0) "$remoteStatus ",
    errorType,
    if (info.isNotEmpty) " ($info)",
    if (wrappedError.isNotEmpty) ": $wrappedError",
    if (remoteError != null) "\n$remoteError",
  ].join();
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RemoteError {
  RemoteError({
    this.status,
    this.errorName,
    this.description,
    this.message,
    this.stacktrace,
  });

  final int? status;

  @JsonKey(name: "error")
  final String? errorName;

  final String? description;

  final String? message;

  final String? stacktrace;

  RemoteError copyWithoutStacktrace() => RemoteError(
    status: status,
    errorName: errorName,
    description: description,
    message: message,
  );

  factory RemoteError.fromJson(Map<String, dynamic> json) =>
      _$RemoteErrorFromJson(json);
  Map<String, dynamic> toJson() => _$RemoteErrorToJson(this);

  @override
  String toString() => jsonEncode(copyWithoutStacktrace());
}
