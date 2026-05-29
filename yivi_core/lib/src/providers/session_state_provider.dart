import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/session_state.dart";
import "irma_repository_provider.dart";

final sessionStateProvider = StreamProvider.family<SessionState, int>((
  ref,
  sessionId,
) {
  final repo = ref.watch(irmaRepositoryProvider);
  return repo.getSessionState(sessionId);
});

/// Whether [sessionId] has dispatched a user interaction that's still waiting
/// for the next [SessionState] from Go. Drives the spinner during Gap B and
/// also covers paths where the interaction is dispatched outside SessionScreen
/// (e.g. the OID4VCI auth-code callback).
///
/// Backed by a [Notifier] rather than a [StreamProvider] so the value is
/// available synchronously on the first build of a remount — the underlying
/// [BehaviorSubject] already knows the answer, but a [StreamProvider] would
/// report `AsyncValue.loading()` for one frame and cause a spinner flicker.
class SessionAwaitingInteractionNotifier extends Notifier<bool> {
  final int sessionId;

  SessionAwaitingInteractionNotifier(this.sessionId);

  @override
  bool build() {
    final repo = ref.watch(irmaRepositoryProvider);
    final sub = repo.isSessionAwaitingInteraction(sessionId).listen((v) {
      state = v;
    });
    ref.onDispose(sub.cancel);
    return repo.isSessionAwaitingInteractionNow(sessionId);
  }
}

final sessionAwaitingInteractionProvider =
    NotifierProvider.family<SessionAwaitingInteractionNotifier, bool, int>(
      (sessionId) => SessionAwaitingInteractionNotifier(sessionId),
    );
