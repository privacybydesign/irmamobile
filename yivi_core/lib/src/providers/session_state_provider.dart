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
