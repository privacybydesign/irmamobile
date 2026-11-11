import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/log_entry.dart";
import "../screens/session/models/disclosure_view_model.dart";
import "irma_repository_provider.dart";
import "schemaless_credentials_list_provider.dart";
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
      // A request names a card by the hash of its instance in one format
      // (an IRMA card's differs from the card's own); the log by the card's.
      final wallet = ref.watch(walletCardsProvider);
      String cardHash(String hash) =>
          wallet
              .firstWhereOrNull(
                (c) =>
                    c.hash == hash ||
                    c.credentialInstanceIds.values.contains(hash),
              )
              ?.hash ??
          hash;
      return lastSharedBundles(
        pickOnes,
        session.requestor,
        (hash) => ref.watch(cardSharesProvider(cardHash(hash))).value,
      );
    });
