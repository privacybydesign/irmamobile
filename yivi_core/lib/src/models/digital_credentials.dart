import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "digital_credentials.g.dart";

/// An OpenID4VP request the platform delivered through the W3C Digital
/// Credentials API instead of through a URL.
///
/// Mirrors `openid4vp.DcApiRequest` in the Go core: [protocol] is the exchange
/// protocol identifier the verifier asked for (`openid4vp-v1-unsigned` or
/// `openid4vp-v1-signed`), [origin] is the caller origin as authenticated by
/// the platform, and [data] is the `data` member of the API call.
///
/// [data] is held decoded rather than as the string the platform hands over,
/// because the core reads it as a JSON object. Everything in it — the response
/// mode, the `dcql_query`, the signature over a signed request — is validated
/// by the core, so nothing is checked here beyond it being an object.
@JsonSerializable(fieldRename: FieldRename.snake)
class DigitalCredentialsRequest {
  final String protocol;
  final String origin;
  final Map<String, dynamic> data;

  DigitalCredentialsRequest({
    required this.protocol,
    required this.origin,
    required this.data,
  });

  factory DigitalCredentialsRequest.fromJson(Map<String, dynamic> json) =>
      _$DigitalCredentialsRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DigitalCredentialsRequestToJson(this);
}

/// Sent by native when the platform routed an OpenID4VP request to Yivi through
/// the Digital Credentials API. Sibling of `HandleURLEvent`, for a session
/// request that did not arrive as a URL.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class HandleDigitalCredentialsRequestEvent extends Event {
  final DigitalCredentialsRequest request;

  HandleDigitalCredentialsRequestEvent({required this.request});

  factory HandleDigitalCredentialsRequestEvent.fromJson(
    Map<String, dynamic> json,
  ) => _$HandleDigitalCredentialsRequestEventFromJson(json);
}

/// Sent to native once the session produced an Authorization Response, so it can
/// hand [response] back to the platform as the `data` member of its response.
///
/// Only the success leg is reported. Native owns the failure leg: a session that
/// ends without this event — cancelled, errored, or abandoned — must be answered
/// with a cancellation to the calling app, so no Dart event is needed for it.
@JsonSerializable(createFactory: false)
class DigitalCredentialsResponseEvent extends Event {
  final String response;

  DigitalCredentialsResponseEvent({required this.response});

  Map<String, dynamic> toJson() =>
      _$DigitalCredentialsResponseEventToJson(this);
}
