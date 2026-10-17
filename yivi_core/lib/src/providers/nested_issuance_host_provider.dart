import "package:flutter_riverpod/flutter_riverpod.dart";

/// Takes over a session that starts while the user adds a card in a sheet,
/// instead of a session screen pushed on top: the Change sheet of a request,
/// or the Add data sheet, registers itself while a card is being added, and
/// the issuance then shows in the sheet (see `handlePointer`).
abstract interface class NestedIssuanceHost {
  /// The request the host adds a card for, or null for a host that adds one
  /// on its own (Add data). A session that starts while another request is
  /// the waiting one is not for this host.
  int? get underlyingSessionId;

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
/// session screen as usual.
///
/// A host for a request takes it only while a request waits
/// ([hasUnderlying]), and only while that is its own request ([isActive]).
/// A host without a request (Add data) takes it only while no session is
/// active at all, so a request that starts meanwhile (a link from elsewhere)
/// still gets its own screen. A session that would replace the current
/// screen (the document read after a face check) goes to the host too: in
/// the sheet there is nothing to replace.
NestedIssuanceHost? hostForNewSession(
  NestedIssuanceHost? host, {
  required bool hasUnderlying,
  required bool Function(int sessionId) isActive,
}) {
  if (host == null) return null;
  final request = host.underlyingSessionId;
  if (request == null) return hasUnderlying ? null : host;
  if (!hasUnderlying) return null;
  return isActive(request) ? host : null;
}
