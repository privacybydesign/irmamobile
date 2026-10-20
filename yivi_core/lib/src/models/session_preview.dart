import "event.dart";
import "schemaless/schemaless_events.dart";
import "session.dart";

/// What a session will be, as far as its pointer says.
enum SessionPreviewKind { disclosure, issuance, signature, unknown }

/// How much a [SessionPreview] knows about who asks.
enum SessionPreviewKnowledge {
  /// In the requestor scheme: its name and logo, as the session will show.
  registered,

  /// An IRMA requestor that is not in the scheme: just its host, also later.
  unregistered,

  /// OpenID4VP or OpenID4VCI: the host the request comes from. Who that is
  /// shows once the session has fetched the request.
  host,

  /// Nothing, not even a host.
  none,
}

/// What the app can show about a session before it starts, worked out by
/// irmago from the pointer and the local configuration only: no server is
/// contacted. The lock screen shows it while the session waits for the PIN.
class SessionPreview {
  final SessionPreviewKind kind;
  final SessionPreviewKnowledge knowledge;

  /// The host the request comes from; empty when not known.
  final String host;

  /// The requestor, for [SessionPreviewKnowledge.registered] and
  /// [SessionPreviewKnowledge.unregistered] only.
  final TrustedParty? requestor;

  /// An e-mail link: the address it adds.
  final String? email;

  const SessionPreview({
    required this.kind,
    required this.knowledge,
    this.host = "",
    this.requestor,
    this.email,
  });

  /// Before irmago has answered, or for a pointer it can't preview.
  static const unknown = SessionPreview(
    kind: SessionPreviewKind.unknown,
    knowledge: SessionPreviewKnowledge.none,
  );

  factory SessionPreview.fromJson(Map<String, dynamic> json) {
    final requestor = json["requestor"];
    return SessionPreview(
      kind: SessionPreviewKind.values.firstWhere(
        (k) => k.name == json["kind"],
        orElse: () => SessionPreviewKind.unknown,
      ),
      knowledge: SessionPreviewKnowledge.values.firstWhere(
        (k) => k.name == json["knowledge"],
        orElse: () => SessionPreviewKnowledge.none,
      ),
      host: json["host"] as String? ?? "",
      requestor: requestor is Map<String, dynamic>
          ? TrustedParty.fromJson(requestor)
          : null,
    );
  }

  /// The preview of [pointer] that needs no irmago: the kind its pointer
  /// names, nothing about who asks.
  factory SessionPreview.ofPointer(SessionPointer pointer) => SessionPreview(
    kind: switch (pointer.irmaqr) {
      "disclosing" => SessionPreviewKind.disclosure,
      "issuing" => SessionPreviewKind.issuance,
      "signing" => SessionPreviewKind.signature,
      _ => SessionPreviewKind.unknown,
    },
    knowledge: SessionPreviewKnowledge.none,
  );

  bool get isIssuance => kind == SessionPreviewKind.issuance;
}

/// Asks irmago what [request] would start and who it is from, without
/// starting it. Answered by a [SessionPreviewEvent] with the same [key].
class PreviewSessionEvent extends Event {
  final String key;
  final SessionPointer request;

  PreviewSessionEvent({required this.key, required this.request});

  Map<String, dynamic> toJson() => {"key": key, "request": request.toJson()};
}

/// irmago's answer to a [PreviewSessionEvent].
class SessionPreviewEvent extends Event {
  final String key;
  final SessionPreview preview;

  SessionPreviewEvent({required this.key, required this.preview});

  factory SessionPreviewEvent.fromJson(Map<String, dynamic> json) =>
      SessionPreviewEvent(
        key: json["key"] as String? ?? "",
        preview: json["preview"] is Map<String, dynamic>
            ? SessionPreview.fromJson(json["preview"] as Map<String, dynamic>)
            : SessionPreview.unknown,
      );
}
