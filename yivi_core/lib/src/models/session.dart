import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../data/irma_repository.dart";
import "protocol.dart";
import "translated_value.dart";

part "session.g.dart";

class MissingPointer implements Exception {
  final String details;

  MissingPointer({required this.details});

  String errorMessage() {
    return "URI does not contain a session or wizard pointer: $details";
  }

  @override
  String toString() {
    return "MissingPointer(details: ${errorMessage()})";
  }
}

/// Interface for all pointers referring to new sessions and issue wizards.
abstract class Pointer {
  Future<void> validate({
    required IrmaRepository irmaRepository,
    RequestorInfo? requestor,
  });

  factory Pointer.fromString(String content) {
    const universalLinkHosts = {"open.yivi.app", "open.staging.yivi.app"};

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

      final hasWizard = json.containsKey("wizard");
      final hasURL = json.containsKey("u");
      if (hasWizard && hasURL) {
        return IssueWizardSessionPointer.fromJson(json);
      } else if (hasWizard) {
        return IssueWizardPointer.fromJson(json);
      } else {
        return SessionPointer.fromJson(json);
      }
    } catch (e) {
      throw MissingPointer(details: e.toString());
    }
  }
}

/// A pointer that refers to an issue wizard only.
@JsonSerializable(fieldRename: FieldRename.snake)
class IssueWizardPointer implements Pointer {
  @JsonKey(name: "wizard", required: true)
  final String wizard;

  IssueWizardPointer(this.wizard);

  factory IssueWizardPointer.fromJson(Map<String, dynamic> json) =>
      _$IssueWizardPointerFromJson(json);
  Map<String, dynamic> toJson() => _$IssueWizardPointerToJson(this);

  @override
  Future<void> validate({
    required IrmaRepository irmaRepository,
    RequestorInfo? requestor,
  }) async {
    if (await irmaRepository.getIssueWizardActive().first) {
      throw UnsupportedError("cannot start wizard within a wizard");
    }

    final scheme = wizard.contains(".") ? wizard.split(".").first : null;

    final irmaConfiguration = await irmaRepository.getIrmaConfiguration().first;
    if (!irmaConfiguration.issueWizards.containsKey(wizard) ||
        !irmaConfiguration.requestorSchemes.containsKey(scheme)) {
      throw ArgumentError.value(wizard, "wizard");
    }

    final demoScheme = irmaConfiguration.requestorSchemes[scheme]!.demo;
    final developerMode = await irmaRepository.getDeveloperMode().first;
    if (!developerMode && demoScheme) {
      throw UnsupportedError(
        "cannot start wizard from demo scheme: developer mode not enabled",
      );
    }

    final wizardData = irmaConfiguration.issueWizards[wizard]!;
    if (demoScheme || wizardData.allowOtherRequestors) {
      return;
    }

    if (requestor == null) {
      throw UnsupportedError("cannot start wizard: unknown requestor");
    }
    if (wizardData.id.split(".").getRange(0, 2).join(".") != requestor.id) {
      throw UnsupportedError(
        "cannot start wizard not belonging to session requestor",
      );
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

/// A request the operating system delivered through the W3C Digital
/// Credentials API.
///
/// One app-level entry point carries two unrelated exchanges, and [protocol]
/// is what tells them apart: `openid4vp-v1-signed` / `openid4vp-v1-unsigned`
/// carry OpenID4VP, while `org-iso-mdoc` carries ISO/IEC 18013-5's own
/// DeviceRequest. The wallet does not have to know which — it forwards whatever
/// the platform reported and the Go core branches on it.
///
/// [origin] is the caller the platform authenticated, and it is load-bearing
/// rather than informational: the session transcript binds to it, so a response
/// produced for one origin cannot be replayed at another.
@JsonSerializable(fieldRename: FieldRename.snake)
class DcApiRequest {
  const DcApiRequest({
    required this.protocol,
    required this.origin,
    required this.data,
  });

  final String protocol;

  final String origin;

  /// The request exactly as the platform delivered it, forwarded unparsed. Its
  /// shape depends on [protocol], which is the Go core's business and not the
  /// app's.
  final Map<String, dynamic> data;

  factory DcApiRequest.fromJson(Map<String, dynamic> json) =>
      _$DcApiRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DcApiRequestToJson(this);
}

/// A pointer that refers to a new IRMA session.
@JsonSerializable(fieldRename: FieldRename.snake)
class SessionPointer implements Pointer {
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
  Protocol protocol;

  /// Whether the session should be continued on the mobile device,
  /// or on the device which has displayed a QR code.
  /// Field is not always specified in QRs now.
  /// To make sure we can override its value if necessary, the field is not final fow now.
  @JsonKey(readValue: _readContinueOnSecondDevice)
  bool continueOnSecondDevice;

  /// OAuth `redirect_uri` for OpenID4VCI auth-code / pre-auth-code flows.
  /// Populated only for [Protocol.openid4vci] pointers; derived from the
  /// inbound universal link's host so staging-host offers redirect to the
  /// staging bounce page (`https://open.staging.yivi.app/-/auth-callback`).
  /// Forwarded as `openid4vci_redirect_uri` to the Go core's session request.
  @JsonKey(name: "openid4vci_redirect_uri", includeIfNull: false)
  final String? openid4vciRedirectUri;

  /// A request the platform delivered through the W3C Digital Credentials API
  /// instead of through a link. When set, [u] is ignored by the Go core and
  /// [protocol] is always [Protocol.openid4vp] — see [DcApiRequest].
  @JsonKey(name: "dc_api", includeIfNull: false)
  final DcApiRequest? dcApi;

  SessionPointer({
    required this.u,
    required this.irmaqr,
    required this.protocol,
    this.continueOnSecondDevice = false,
    this.openid4vciRedirectUri,
    this.dcApi,
  });

  /// A session the platform delivered through the Digital Credentials API.
  ///
  /// [u] and [irmaqr] carry no meaning here: the request arrives whole rather
  /// than being fetched from a URL, so they are filled to satisfy the shape the
  /// Go core's `SessionRequestData` embeds from `irma.Qr`.
  factory SessionPointer.dcApi(DcApiRequest request) => SessionPointer(
    u: "",
    irmaqr: "disclosing",
    protocol: Protocol.openid4vp,
    dcApi: request,
  );

  factory SessionPointer.fromJson(Map<String, dynamic> json) =>
      _$SessionPointerFromJson(json);
  Map<String, dynamic> toJson() => _$SessionPointerToJson(this);

  @override
  Future<void> validate({
    required IrmaRepository irmaRepository,
    RequestorInfo? requestor,
  }) async {}
}

/// A pointer that refers to an issue wizard being followed by an IRMA session.
class IssueWizardSessionPointer implements IssueWizardPointer, SessionPointer {
  final IssueWizardPointer _wizardPointer;
  final SessionPointer _sessionPointer;

  IssueWizardSessionPointer(this._wizardPointer, this._sessionPointer);

  factory IssueWizardSessionPointer.fromJson(Map<String, dynamic> json) =>
      IssueWizardSessionPointer(
        IssueWizardPointer.fromJson(json),
        SessionPointer.fromJson(json),
      );

  @override
  bool get continueOnSecondDevice => _sessionPointer.continueOnSecondDevice;

  @override
  set continueOnSecondDevice(bool value) =>
      _sessionPointer.continueOnSecondDevice = value;

  @override
  String get irmaqr => _sessionPointer.irmaqr;

  @override
  String get wizard => _wizardPointer.wizard;

  @override
  String get u => _sessionPointer.u;

  @override
  Protocol get protocol => _sessionPointer.protocol;

  @override
  String? get openid4vciRedirectUri => _sessionPointer.openid4vciRedirectUri;

  /// Delegated like every other member. In practice null: an issue wizard is
  /// followed from a link, and a link carries no DC API request.
  @override
  DcApiRequest? get dcApi => _sessionPointer.dcApi;

  @override
  Map<String, dynamic> toJson() => {
    ..._wizardPointer.toJson(),
    ..._sessionPointer.toJson(),
  };

  @override
  Future<void> validate({
    required IrmaRepository irmaRepository,
    RequestorInfo? requestor,
  }) async {
    await _wizardPointer.validate(
      irmaRepository: irmaRepository,
      requestor: requestor,
    );
    await _sessionPointer.validate(
      irmaRepository: irmaRepository,
      requestor: requestor,
    );
  }

  @override
  set protocol(Protocol protocol) {
    _sessionPointer.protocol = protocol;
  }
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

@JsonSerializable(fieldRename: FieldRename.snake)
class RequestorInfo {
  final String? id;

  final TranslatedValue name;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue industry;

  final String? logo;

  final String? logoPath;

  final bool unverified;

  final List<String> hostnames;

  RequestorInfo({
    required this.name,
    this.unverified = true,
    this.hostnames = const [],
    this.industry = const TranslatedValue.empty(),
    this.id,
    this.logo,
    this.logoPath,
  });
  factory RequestorInfo.fromJson(Map<String, dynamic> json) =>
      _$RequestorInfoFromJson(json);
  Map<String, dynamic> toJson() => _$RequestorInfoToJson(this);
}

/// Whether unlocking the app for this pointer has to be done with the PIN
/// rather than with biometrics.
///
/// Biometric unlock opens the app shell without refreshing the keyshare token
/// that the idle lock cleared, so a session that needs that token would go on to
/// demand the PIN anyway — a second prompt for an unlock the user already did.
/// Hiding biometrics whenever a session is waiting is what avoids that.
///
/// A session delivered through the Digital Credentials API is the exception, and
/// not by special-casing: it discloses an EUDI credential, which is held locally
/// and signed with a local device key, so nothing in it ever reaches the keyshare
/// server. `Status_RequestPin` is emitted from one place in irmago — the IRMA
/// adapters — and that path is not on this one. There is therefore no second
/// prompt to avoid, and refusing biometrics only makes the user type a PIN to
/// answer a request a browser is waiting on.
bool pointerNeedsPinUnlock(Pointer? pointer) {
  if (pointer == null) return false;
  if (pointer is SessionPointer) return pointer.dcApi == null;
  // Anything else is an IRMA flow — an issue wizard, a legacy session — and
  // those do need the token. Defaulting to "PIN" keeps a new pointer type safe
  // until somebody decides otherwise.
  return true;
}
