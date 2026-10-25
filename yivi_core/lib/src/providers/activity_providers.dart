import "dart:async";

import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/log_entry.dart";
import "../screens/activity/activity_entry.dart";
import "../screens/activity/activity_query.dart";
import "irma_repository_provider.dart";
import "schemaless_credentials_list_provider.dart";

/// How many entries the Activity tab asks for at a time.
const activityPageSize = 20;

/// The entries of the Activity tab loaded so far, newest first.
class ActivityLogState {
  final ActivityQuery filter;
  final List<LogInfo> entries;

  /// Continues with the next page; null once the last one came in.
  final String? nextCursor;

  /// Whether a page is on its way.
  final bool loading;

  /// Whether the first page for [filter] came in.
  final bool loaded;

  /// The counts of the first page's query: [LogCounts.total] is how many
  /// entries match in all.
  final LogCounts? counts;

  const ActivityLogState({
    this.filter = ActivityQuery.empty,
    this.entries = const [],
    this.nextCursor,
    this.loading = false,
    this.loaded = false,
    this.counts,
  });

  bool get moreAvailable => nextCursor != null;
}

/// The Activity tab's log: irmago filters, searches and pages it; this keeps
/// the pages loaded so far, and asks again when the log changed.
class ActivityLogNotifier extends Notifier<ActivityLogState> {
  /// Bumped for every new first page, so an answer to an older question is
  /// dropped instead of mixed in.
  var _generation = 0;

  @override
  ActivityLogState build() {
    final repo = ref.watch(irmaRepositoryProvider);
    final sub = repo.logsChanged.listen((_) => refresh());
    ref.onDispose(sub.cancel);
    scheduleMicrotask(refresh);
    return const ActivityLogState(loading: true);
  }

  /// Shows the entries matching [filter], from the newest.
  void setFilter(ActivityQuery filter) {
    if (filter == state.filter) return;
    state = ActivityLogState(filter: filter, loading: true);
    refresh();
  }

  /// Loads the first page again, keeping what is shown until it is in.
  Future<void> refresh() async {
    final generation = ++_generation;
    final filter = state.filter;
    state = ActivityLogState(
      filter: filter,
      entries: state.entries,
      nextCursor: state.nextCursor,
      loading: true,
      loaded: state.loaded,
      counts: state.counts,
    );
    try {
      final page = await ref
          .read(irmaRepositoryProvider)
          .queryLogs(
            LogQuery(
              filter: filter.toLogFilter(),
              limit: activityPageSize,
              withCounts: true,
            ),
          );
      if (generation != _generation || !ref.mounted) return;
      state = ActivityLogState(
        filter: filter,
        entries: page.entries,
        nextCursor: page.nextCursor,
        loaded: true,
        counts: page.counts,
      );
    } catch (_) {
      if (generation != _generation || !ref.mounted) return;
      state = ActivityLogState(
        filter: filter,
        entries: state.entries,
        loaded: true,
        counts: state.counts,
      );
    }
  }

  /// Loads the next page, when there is one and none is on its way.
  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loading) return;
    final generation = _generation;
    final filter = state.filter;
    state = ActivityLogState(
      filter: filter,
      entries: state.entries,
      nextCursor: cursor,
      loading: true,
      loaded: true,
      counts: state.counts,
    );
    LogPage? page;
    try {
      page = await ref
          .read(irmaRepositoryProvider)
          .queryLogs(
            LogQuery(
              filter: filter.toLogFilter(),
              cursor: cursor,
              limit: activityPageSize,
            ),
          );
    } catch (_) {
      page = null;
    }
    if (generation != _generation || !ref.mounted) return;
    state = ActivityLogState(
      filter: filter,
      entries: [...state.entries, ...?page?.entries],
      // A failed page is not retried by scrolling: it would ask again for
      // every pixel. The next change of the log starts over.
      nextCursor: page?.nextCursor,
      loaded: true,
      counts: state.counts,
    );
  }
}

final activityLogProvider =
    NotifierProvider<ActivityLogNotifier, ActivityLogState>(
      ActivityLogNotifier.new,
    );

/// How many of a card's entries its details show.
const cardActivityLimit = 5;

/// The activity of one card, for its details.
class CardActivity {
  /// The newest entries about the card, at most [cardActivityLimit].
  final List<LogInfo> entries;

  /// How many entries there are about the card in all.
  final int total;

  /// How often the card was shared, with how many parties, and when last.
  final int shares;
  final int parties;
  final DateTime? lastShared;

  const CardActivity({
    required this.entries,
    required this.total,
    required this.shares,
    required this.parties,
    this.lastShared,
  });
}

/// The activity of one card ([Credential.hash]), asked again when the log
/// changes.
final cardActivityProvider = FutureProvider.autoDispose
    .family<CardActivity, String>((ref, hash) async {
      final repo = ref.watch(irmaRepositoryProvider);
      final sub = repo.logsChanged.listen((_) => ref.invalidateSelf());
      ref.onDispose(sub.cancel);
      final page = await repo.queryLogs(
        LogQuery(
          filter: LogFilter(credentialHash: hash),
          limit: cardActivityLimit,
          withCounts: true,
        ),
      );
      final sharedWith = await repo.listParties(
        LogFilter(credentialHash: hash, types: const [LogType.disclosure]),
      );
      return CardActivity(
        entries: page.entries,
        total: page.counts?.total ?? page.entries.length,
        shares: sharedWith.fold(0, (n, p) => n + p.count),
        parties: sharedWith.length,
        lastShared: sharedWith.map((p) => p.lastTime).maxOrNull,
      );
    });

/// Everyone in the activity log, the most recent first, asked again when the
/// log changes.
final activityPartiesProvider = FutureProvider.autoDispose<List<PartySummary>>((
  ref,
) async {
  final repo = ref.watch(irmaRepositoryProvider);
  final sub = repo.logsChanged.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return repo.listParties(const LogFilter(includeHidden: false));
});

/// The card types the log knows that are no longer in the wallet: what was
/// deleted, to still filter on. One per type, drawn as the log kept it.
final removedCardTypesProvider =
    FutureProvider.autoDispose<List<ActivityCardRef>>((ref) async {
      final repo = ref.watch(irmaRepositoryProvider);
      final wallet = ref.watch(walletCardsProvider);
      final sub = repo.logsChanged.listen((_) => ref.invalidateSelf());
      ref.onDispose(sub.cancel);
      final page = await repo.queryLogs(
        const LogQuery(filter: LogFilter(types: [LogType.removal]), limit: 200),
      );
      final held = {for (final c in wallet) c.credentialId};
      final seen = <String>{};
      return [
        for (final log in page.entries)
          for (final c
              in log.removalLog?.credentials ?? const <LogCredential>[])
            if (!held.contains(c.credentialId) && seen.add(c.credentialId))
              ActivityCardRef(
                credentialId: c.credentialId,
                art: ActivityEntry.artFor(c, wallet),
              ),
      ];
    });
