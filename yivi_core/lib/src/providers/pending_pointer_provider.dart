import "../models/session.dart";
import "../util/stream_mirror.dart";

/// `PendingPointerQueue.pending`, the queued session or URL pointer. Used by
/// the lock-screen [PinScreen] to hide biometric while a session is
/// pending: a biometric unlock doesn't refresh the keyshare token, so it
/// would force a second PIN prompt at the session. Entering the PIN directly
/// refreshes the token and avoids that.
final pendingPointerProvider = mirrorProvider<Pointer?>(
  (repo) => repo.pendingPointers.pending,
  first: (_) => null,
);
