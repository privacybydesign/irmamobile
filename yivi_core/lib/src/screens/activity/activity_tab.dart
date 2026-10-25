import "dart:async";

import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../providers/activity_providers.dart";
import "../../providers/credentials_search.dart";
import "../../providers/pane_selection_provider.dart";
import "../../providers/search_query_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../util/after_frame.dart";
import "../../util/string.dart";
import "../../widgets/empty_list_message.dart";
import "../../widgets/end_of_list_indicator.dart";
import "../../widgets/glass/floating_bar_placement.dart";
import "../../widgets/glass/glass_search_field.dart";
import "../../widgets/glass/search_scroll_edge.dart";
import "../../widgets/loading_indicator.dart";
import "../../widgets/two_pane.dart";
import "../data/wallet/wallet_transition.dart";
import "activity_detail_screen.dart";
import "activity_entry.dart";
import "widgets/activity_card.dart";
import "widgets/activity_kind_tags.dart";

class ActivityTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<ActivityTab> {
  final _scrollController = ScrollController();

  /// Outlives this State, like the Data tab's search.
  late String _query = ref.read(activitySearchQueryProvider);
  late final _search = TextEditingController(text: _query);

  /// Waits for a pause in typing before irmago is asked.
  Timer? _searchDelay;

  void _onQuery(String q) {
    setState(() => _query = q);
    ref.read(activitySearchQueryProvider.notifier).set(q);
    _searchDelay?.cancel();
    _searchDelay = Timer(const Duration(milliseconds: 250), _applyFilter);
  }

  /// The picked tag; null shows everything.
  ActivityKind? _filter;

  /// The entries shown last, for the default of the tablet detail pane.
  List<LogInfo> _latestEntries = const [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_listenToScroll);
    // A search kept from before needs the translations of the tags.
    if (_query.isNotEmpty) afterFrame(_applyFilter);
  }

  @override
  void dispose() {
    _searchDelay?.cancel();
    _search.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Asks irmago for the entries of the picked tag that match the search.
  /// irmago searches names, values and signed messages; the tags' own labels
  /// are in the app's language, so those are matched here.
  void _applyFilter() {
    if (!mounted) return;
    final query = normaliseForSearch(_query);
    final textOrTypes = query.isEmpty
        ? const <LogType>[]
        : [
            for (final type in LogType.values)
              if (normaliseForSearch(
                [
                  FlutterI18n.translate(
                    context,
                    ActivityKind.of(type).labelKey,
                  ),
                  FlutterI18n.translate(
                    context,
                    ActivityKind.of(type).subtitleKey,
                  ),
                ].join(" "),
              ).contains(query))
                type,
          ];
    ref
        .read(activityLogProvider.notifier)
        .setFilter(
          ActivityLogFilter(
            types: [
              for (final type in LogType.values)
                if (_filter != null && ActivityKind.of(type) == _filter) type,
            ],
            text: _query,
            textOrTypes: textOrTypes,
          ),
        );
  }

  void _loadMoreLogs() => ref.read(activityLogProvider.notifier).loadMore();

  void _addPostFrameCallback() {
    // After list is initially rendered, there might not be enough logs to trigger the scroll controller.
    // In that case, load more logs to fully fill the screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_scrollController.hasClients ||
          !_scrollController.position.haveDimensions) {
        return;
      }
      if (_scrollController.position.maxScrollExtent -
              _scrollController.position.minScrollExtent <
          80) {
        _loadMoreLogs();
      }
    });
  }

  void _listenToScroll() {
    // When scrollbar is at the end, load more logs
    if (_scrollController.position.maxScrollExtent -
            _scrollController.position.pixels <
        80) {
      _loadMoreLogs();
    }
  }

  /// The kind tags that filter the list.
  Widget _tags({bool clip = false}) => ActivityKindTags(
    selected: _filter,
    clip: clip,
    onSelected: (kind) {
      setState(() => _filter = kind);
      _applyFilter();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    },
  );

  /// The floating search field, and the tags under it once there is
  /// activity.
  double _headerHeight(bool withTags) =>
      60 + (withTags ? ActivityKindTags.height + 8 : 0);

  /// Whether there is any activity to filter: the tags show then.
  bool _hasActivity(ActivityLogState state) =>
      state.entries.isNotEmpty ||
      _filter != null ||
      _query.isNotEmpty ||
      (state.counts?.byType.values.any((n) => n > 0) ?? false);

  Widget _buildLogEntries(BuildContext context, ActivityLogState state) {
    final logEntries = state.entries;
    final moreLogsAvailable = state.moreAvailable;
    final hasActivity = _hasActivity(state);
    _addPostFrameCallback();
    // The detail pane shows the newest entry until one is picked; it was
    // built before the entries came in, so build it again.
    final firstEntries = _latestEntries.isEmpty && logEntries.isNotEmpty;
    _latestEntries = logEntries;
    if (firstEntries && useHomePanes(context)) {
      afterFrame(() => setState(() {}));
    }
    final local = FlutterI18n.currentLocale(context).toString();
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);

    final searching = _query.trim().isNotEmpty;
    final shown = logEntries;
    final tagsInList = usePhoneLandscape(context);
    // The entry in the detail pane: the picked one, or the newest.
    final open = useHomePanes(context)
        ? ref.watch(selectedActivityProvider) ?? logEntries.firstOrNull
        : null;

    // A header per month, then its rows.
    final groups = <List<LogInfo>>[];
    for (final entry in shown) {
      final last = groups.lastOrNull;
      if (last == null ||
          last.last.time.toLocal().month != entry.time.toLocal().month ||
          last.last.time.toLocal().year != entry.time.toLocal().year) {
        groups.add([entry]);
      } else {
        last.add(entry);
      }
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        16,
        padding.top +
            FloatingBarPlacement.topGap(context) +
            _headerHeight(hasActivity && !tagsInList),
        16,
        padding.bottom + bottomBarSpace(context),
      ),
      children: [
        // In the list column they stay inside it, clear of the pane.
        if (tagsInList && hasActivity) _tags(clip: true),
        if (shown.isEmpty && searching)
          const EmptyListMessage("activity.no_results")
        else if (shown.isEmpty && _filter != null)
          EmptyListMessage("activity.filter_empty.${_filter!.name}")
        else if (shown.isEmpty)
          const EmptyListMessage("activity.empty_placeholder")
        else ...[
          for (final group in groups) ...[
            PushAway(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                child: Semantics(
                  header: true,
                  child: Text(
                    DateFormat(
                      "MMMM",
                      local,
                    ).format(group.first.time.toLocal()).toCapitalized(),
                    style: palette.display(18),
                  ),
                ),
              ),
            ),
            for (final entry in group)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ActivityCard(
                  key: ValueKey(ActivityEntry.fromLog(entry).key),
                  logEntry: entry,
                  selected: open != null && sameLog(open, entry),
                ),
              ),
          ],
          PushAway(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: EndOfListIndicator(isLoading: moreLogsAvailable),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final top = padding.top + FloatingBarPlacement.topGap(context);
    final state = ref.watch(activityLogProvider);
    final withTags = _hasActivity(state);
    // Held sideways the tags scroll with the list, under the search field,
    // instead of floating with it.
    final tagsInList = usePhoneLandscape(context);
    // The entries scroll under the search field and the tags; the edge goes
    // away with them when an entry opens.
    final list = SearchScrollEdge(
      height: top + _headerHeight(withTags) - 4,
      top: top,
      row: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassSearchField(
            fieldKey: const Key("activity_search_field"),
            hintKey: "activity.search_placeholder",
            controller: _search,
            onChanged: _onQuery,
          ),
          if (withTags && !tagsInList) ...[const SizedBox(height: 8), _tags()],
        ],
      ),
      child: !state.loaded
          ? Center(child: LoadingIndicator())
          : _buildLogEntries(context, state),
    );

    return Scaffold(
      backgroundColor: palette.background,
      body: useHomePanes(context) ? _withDetailPane(list) : list,
    );
  }

  /// The tablet layout: the activity next to the details of the picked
  /// entry (the newest until the user picks one).
  Widget _withDetailPane(Widget list) {
    final entry =
        ref.watch(selectedActivityProvider) ?? _latestEntries.firstOrNull;
    return TwoPane(
      list: list,
      detail: entry == null
          ? null
          : ActivityDetailPane(
              key: ValueKey(ActivityEntry.fromLog(entry).key),
              logEntry: entry,
            ),
    );
  }
}
