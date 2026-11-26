import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/credential.dart";
import "../models/log_entry.dart";
import "../screens/session/models/disclosure_plan_view.dart";
import "irma_repository_provider.dart";
import "session_state_provider.dart";
import "wallet_cards_provider.dart";

/// The disclosures (and signatures) of the card with [hash], newest first:
/// who it was shared with, and when. The last 50 are enough to know.
final cardSharesProvider = FutureProvider.autoDispose
    .family<List<LogInfo>, String>((ref, hash) async {
      final page = await ref
          .read(activityLogClientProvider)
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

/// When the card with [hash] was last shared with [requestor] and with
/// anyone, from its shares ([cardSharesProvider], newest first).
LastShared lastSharedOf(List<LogInfo> shares, TrustedParty requestor) =>
    LastShared(
      withRequestor: shares
          .firstWhereOrNull((log) => sameParty(log.requestor, requestor))
          ?.time,
      withAnyone: shares.firstOrNull?.time,
    );

/// What was shared before, per candidate hash, for the request of
/// [sessionId] ([LastShared.never] while it is looked up). A request names a
/// card by the hash of its instance in one format (an IRMA card's differs
/// from the card's own); the log by the card's.
final sharesOfProvider = Provider.autoDispose.family<SharesOf, int>((
  ref,
  sessionId,
) {
  final session = ref.watch(sessionStateProvider(sessionId)).value;
  final plan = session?.disclosurePlan;
  if (session == null || plan == null) return (_) => LastShared.never;
  final wallet = ref.watch(walletCardsProvider);
  String cardHash(String hash) =>
      wallet
          .firstWhereOrNull(
            (c) =>
                c.hash == hash || c.credentialInstanceIds.values.contains(hash),
          )
          ?.hash ??
      hash;
  final known = <String, LastShared>{};
  for (final choice in plan.choices) {
    for (final option in choice.options) {
      for (final slot in option.slots) {
        for (final c in slot.candidates) {
          final shares = ref.watch(cardSharesProvider(cardHash(c.hash))).value;
          if (shares != null) {
            known[c.hash] = lastSharedOf(shares, session.requestor);
          }
        }
      }
    }
  }
  return (hash) => known[hash] ?? LastShared.never;
});
