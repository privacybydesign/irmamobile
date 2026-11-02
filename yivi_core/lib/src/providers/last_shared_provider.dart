import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/log_entry.dart";
import "../screens/session/models/disclosure_view_model.dart";
import "irma_repository_provider.dart";
import "session_state_provider.dart";

/// The disclosures (and signatures) of the card with [hash], newest first:
/// who it was shared with, and when. The last 50 are enough to know.
final cardSharesProvider = FutureProvider.autoDispose
    .family<List<LogInfo>, String>((ref, hash) async {
      final page = await ref
          .read(irmaRepositoryProvider)
          .queryLogs(
            LogQuery(
              filter: LogFilter(
                types: const [LogType.disclosure, LogType.signature],
                credentialHash: hash,
              ),
              limit: 50,
            ),
          );
      return page.entries;
    });

/// The cards the request [sessionId] starts on, by what was shared before
/// ([lastSharedBundles]); empty while that is being looked up.
final lastSharedBundlesProvider = Provider.autoDispose
    .family<Map<int, Set<String>>, int>((ref, sessionId) {
      final session = ref.watch(sessionStateProvider(sessionId)).value;
      final pickOnes = session?.disclosurePlan?.disclosureChoicesOverview;
      if (session == null || pickOnes == null) return const {};
      return lastSharedBundles(
        pickOnes,
        session.requestor,
        (hash) => ref.watch(cardSharesProvider(hash)).value,
      );
    });
