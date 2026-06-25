import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/session.dart";
import "irma_repository_provider.dart";

/// Mirrors `repo.getPendingPointer()` (the queued session/URL pointer) into a
/// Riverpod Notifier, same shape as [AppLockedNotifier]. Used by the lock-screen
/// [PinScreen] to hide biometric while a session is pending: a biometric unlock
/// doesn't refresh the keyshare token, so it would force a second PIN prompt at
/// the session. Entering the PIN directly refreshes the token and avoids that.
class PendingPointerNotifier extends Notifier<Pointer?> {
  @override
  Pointer? build() {
    final repo = ref.watch(irmaRepositoryProvider);
    final sub = repo.getPendingPointer().listen((v) => state = v);
    ref.onDispose(sub.cancel);
    return null;
  }
}

final pendingPointerProvider =
    NotifierProvider<PendingPointerNotifier, Pointer?>(
      PendingPointerNotifier.new,
    );
