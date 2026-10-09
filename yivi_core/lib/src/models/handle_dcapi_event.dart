import "package:json_annotation/json_annotation.dart";

import "event.dart";
import "session.dart";

part "handle_dcapi_event.g.dart";

/// A request the operating system delivered through the W3C Digital
/// Credentials API.
///
/// The counterpart to [HandleURLEvent], and deliberately separate from it: a
/// DC API request does not arrive as a URL. It arrives as three fields the
/// platform authenticated — the protocol it negotiated, the origin it verified,
/// and the request itself — none of which survive being squeezed into a link.
///
/// Both end up in the same place. The repository turns this into a
/// [SessionPointer] and puts it on the pending-pointer stream, so navigation,
/// consent and the session itself follow exactly the path a universal link
/// takes.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class HandleDcApiEvent extends Event {
  HandleDcApiEvent({
    required this.protocol,
    required this.origin,
    required this.data,
  });

  /// The protocol identifier the platform negotiated, e.g. `org-iso-mdoc` or
  /// `openid4vp-v1-unsigned`. Forwarded without interpretation.
  final String protocol;

  /// The origin the platform authenticated. The session transcript binds to
  /// this, so it is not decoration: a response built for one origin is not
  /// valid at another.
  final String origin;

  /// The request as delivered, forwarded unparsed to the Go core.
  final Map<String, dynamic> data;

  factory HandleDcApiEvent.fromJson(Map<String, dynamic> json) =>
      _$HandleDcApiEventFromJson(json);

  SessionPointer toPointer() => SessionPointer.dcApi(
    DcApiRequest(protocol: protocol, origin: origin, data: data),
  );
}
