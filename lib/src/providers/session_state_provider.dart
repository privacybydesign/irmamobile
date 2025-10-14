import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session_state.dart';
import 'irma_repository_provider.dart';

final sessionStateProvider = StreamProvider.family<SessionState, int>((ref, sessionID) async* {
  final repo = ref.watch(irmaRepositoryProvider);
  await for (final state in repo.getSessionState(sessionID)) {
    yield state;
  }
});
