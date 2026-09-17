/// Tracks the session started by a wizard item whose issued credential is not
/// known in advance.
///
/// Go emits the session id *after* the session starts, so [track] receives the
/// id as a [Future]. A visibility change (the user returning to the wizard) can
/// fire before that future resolves. Reading a plain `int? _sessionID` field in
/// that window sees `null` and silently drops the session, stalling the wizard
/// (see issue #623). Holding the pending future instead lets readers await it,
/// so the id is never lost regardless of ordering.
class PendingWizardSession {
  Future<int>? _pending;

  /// Whether a session is currently being tracked. `false` means no session is
  /// expected, so callers must not await [resolve] blindly (there is nothing to
  /// wait for).
  bool get isTracking => _pending != null;

  /// Starts tracking the session whose id will complete [sessionId]. Any
  /// previously tracked session is replaced.
  void track(Future<int> sessionId) => _pending = sessionId;

  /// Stops tracking, so a later visibility change won't handle the session
  /// again once it has been dealt with.
  void clear() => _pending = null;

  /// Awaits the tracked session id, or returns `null` if nothing is being
  /// tracked.
  ///
  /// Awaiting is safe even when the id hasn't been emitted yet: the caller waits
  /// for it rather than observing a transient `null`, which is the whole point
  /// of holding the future instead of a possibly-unset field. When no session
  /// is tracked this returns `null` immediately, so it never hangs.
  Future<int?> resolve() async {
    final pending = _pending;
    if (pending == null) return null;
    return pending;
  }
}
