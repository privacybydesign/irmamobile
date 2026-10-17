import "package:flutter_riverpod/flutter_riverpod.dart";

/// Takes over a session that starts while a request is waiting, instead of a
/// session screen pushed on top: the Change sheet registers itself while the
/// user adds a card for that request in it, and the issuance then shows in
/// the sheet (see `handlePointer`).
abstract interface class NestedIssuanceHost {
  /// The request the host adds a card for. A session that starts while
  /// another request is the waiting one is not for this host.
  int get underlyingSessionId;

  /// The session [sessionId] has started; Go is contacting the issuer.
  void attach(int sessionId);
}

/// The host waiting for a nested session, if any.
final nestedIssuanceHostProvider =
    NotifierProvider<NestedIssuanceHostNotifier, NestedIssuanceHost?>(
      NestedIssuanceHostNotifier.new,
    );

class NestedIssuanceHostNotifier extends Notifier<NestedIssuanceHost?> {
  @override
  NestedIssuanceHost? build() => null;

  void register(NestedIssuanceHost host) => state = host;

  /// Only removes [host] itself, not a host that registered after it.
  void unregister(NestedIssuanceHost host) {
    if (state == host) state = null;
  }
}

/// The host that takes a session starting now, or null when it gets its own
/// session screen as usual: only while a request waits ([hasUnderlying]),
/// and only for the request the registered host belongs to ([isActive]). A
/// session that would replace the current screen (the document read after a
/// face check) goes to the host too: in the sheet there is nothing to
/// replace.
NestedIssuanceHost? hostForNewSession(
  NestedIssuanceHost? host, {
  required bool hasUnderlying,
  required bool Function(int sessionId) isActive,
}) {
  if (host == null || !hasUnderlying) return null;
  return isActive(host.underlyingSessionId) ? host : null;
}
