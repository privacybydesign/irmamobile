import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/session_state.dart";
import "irma_repository_provider.dart";
import "stream_mirror.dart";

final sessionStateProvider = StreamProvider.family<SessionState, int>((
  ref,
  sessionId,
) {
  return ref.watch(sessionRepositoryProvider).getSessionState(sessionId);
});

/// The request a nested issuance [sessionId] is for: the disclosure session
/// waiting underneath it, or null. Gives the issuance permission its "For
/// {requestor} · step n of m" and the values that request needs.
final underlyingDisclosureProvider = StreamProvider.family<SessionState?, int>(
  (ref, sessionId) =>
      ref.watch(sessionRepositoryProvider).underlyingDisclosure(sessionId),
);

/// Whether [sessionId] has dispatched a user interaction that's still waiting
/// for the next [SessionState] from Go. Drives the spinner during Gap B and
/// also covers paths where the interaction is dispatched outside SessionScreen
/// (e.g. the OID4VCI auth-code callback).
///
/// Backed by a [Notifier] rather than a [StreamProvider] so the value is
/// available synchronously on the first build of a remount — the underlying
/// [BehaviorSubject] already knows the answer, but a [StreamProvider] would
/// report `AsyncValue.loading()` for one frame and cause a spinner flicker.
final sessionAwaitingInteractionProvider =
    NotifierProvider.family<StreamMirror<bool>, bool, int>(
      (sessionId) => StreamMirror(
        (repo) => repo.sessions.isAwaitingInteraction(sessionId),
        (repo) => repo.sessions.isAwaitingInteractionNow(sessionId),
      ),
    );
