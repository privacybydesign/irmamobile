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
final sessionAwaitingInteractionProvider = StreamProvider.family<bool, int>((
  ref,
  sessionId,
) {
  final repo = ref.watch(irmaRepositoryProvider);
  return repo.isSessionAwaitingInteraction(sessionId);
});
