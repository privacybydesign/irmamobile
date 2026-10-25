import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/log_entry.dart";
import "irma_repository_provider.dart";

/// How many entries the Activity tab asks for at a time.
const activityPageSize = 20;

/// What the Activity tab shows: entries of these [types] (all when empty)
/// whose text matches [text], or whose type is in [textOrTypes] (the types
/// whose label matched [text] in the app's language).
class ActivityLogFilter {
  final List<LogType> types;
  final String text;
  final List<LogType> textOrTypes;

  const ActivityLogFilter({
    this.types = const [],
    this.text = "",
    this.textOrTypes = const [],
  });

  LogFilter toLogFilter() => LogFilter(
    types: types.isEmpty ? null : types,
    text: text.trim().isEmpty ? null : text,
    textOrTypes: text.trim().isEmpty || textOrTypes.isEmpty
        ? null
        : textOrTypes,
  );

  @override
  bool operator ==(Object other) =>
      other is ActivityLogFilter &&
      _same(types, other.types) &&
      text == other.text &&
      _same(textOrTypes, other.textOrTypes);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(types), text, Object.hashAll(textOrTypes));
}

bool _same(List<LogType> a, List<LogType> b) =>
    a.length == b.length && a.indexed.every((e) => b[e.$1] == e.$2);

/// The entries of the Activity tab loaded so far, newest first.
class ActivityLogState {
  final ActivityLogFilter filter;
  final List<LogInfo> entries;

  /// Continues with the next page; null once the last one came in.
  final String? nextCursor;

  /// Whether a page is on its way.
  final bool loading;

  /// Whether the first page for [filter] came in.
  final bool loaded;

  /// The counts per type of the first page's query.
  final LogCounts? counts;

  const ActivityLogState({
    this.filter = const ActivityLogFilter(),
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
  void setFilter(ActivityLogFilter filter) {
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
const cardActivityLimit = 10;

/// The newest entries about one card ([Credential.hash]), asked again when
/// the log changes.
final cardActivityProvider = FutureProvider.autoDispose
    .family<List<LogInfo>, String>((ref, hash) async {
      final repo = ref.watch(irmaRepositoryProvider);
      final sub = repo.logsChanged.listen((_) => ref.invalidateSelf());
      ref.onDispose(sub.cancel);
      final page = await repo.queryLogs(
        LogQuery(
          filter: LogFilter(credentialHash: hash),
          limit: cardActivityLimit,
        ),
      );
      return page.entries;
    });
