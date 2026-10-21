import "dart:async";

import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../models/schemaless/session_state.dart";
import "../../providers/credentials_search.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/pane_selection_provider.dart";
import "../../providers/search_query_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../util/string.dart";
import "../../widgets/end_of_list_indicator.dart";
import "../../widgets/glass/floating_bar_placement.dart";
import "../../widgets/glass/glass_search_field.dart";
import "../../widgets/glass/scroll_edge.dart";
import "../../widgets/loading_indicator.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/two_pane.dart";
import "../data/wallet/wallet_transition.dart";
import "activity_detail_screen.dart";
import "activity_entry.dart";
import "history_repository.dart";
import "widgets/activity_card.dart";
import "widgets/activity_kind_tags.dart";

class ActivityTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<ActivityTab> {
  late final HistoryRepository _historyRepo;
  final _scrollController = ScrollController();
  late StreamSubscription _repoStateSubscription;

  /// Outlives this State, like the Data tab's search.
  late String _query = ref.read(activitySearchQueryProvider);
  late final _search = TextEditingController(text: _query);

  void _onQuery(String q) {
    setState(() => _query = q);
    ref.read(activitySearchQueryProvider.notifier).set(q);
  }

  /// The picked tag; null shows everything.
  ActivityKind? _filter;

  /// The entries shown last, for the default of the tablet detail pane.
  List<LogInfo> _latestEntries = const [];

  @override
  void initState() {
    super.initState();
    //Delay to make build context available
    Future.delayed(Duration.zero).then((_) async {
      _loadInitialLogs();
      if (!mounted) {
        return;
      }
      _repoStateSubscription = IrmaRepositoryProvider.of(context)
          .getEvents()
          .listen((event) {
            if (event is SessionStateEvent &&
                event.sessionState.status == SessionStatus.success) {
              _loadInitialLogs();
            }
          });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // only init _historyRepo once...
    try {
      _historyRepo;
    } catch (_) {
      _historyRepo = HistoryRepository(IrmaRepositoryProvider.of(context));
    }
  }

  @override
  void dispose() {
    _historyRepo.dispose();
    _repoStateSubscription.cancel();
    _search.dispose();
    super.dispose();
  }

  void _loadInitialLogs() {
    IrmaRepositoryProvider.of(context).bridgedDispatch(LoadLogsEvent(max: 10));
  }

  Future<void> _loadMoreLogs() async {
    final historyState = await _historyRepo.getHistoryState().first;
    if (historyState.moreLogsAvailable && !historyState.loading && mounted) {
      IrmaRepositoryProvider.of(context).bridgedDispatch(
        LoadLogsEvent(
          before:
              historyState.oldestLoaded ?? historyState.logEntries.last.time,
          max: 10,
        ),
      );
    }
  }

  void _addPostFrameCallback() {
    // After list is initially rendered, there might not be enough logs to trigger the scroll controller.
    // In that case, load more logs to fully fill the screen.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scrollController.position.haveDimensions) {
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
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    },
  );

  /// The floating search field, and the tags under it once there is
  /// activity.
  double _headerHeight(bool withTags) =>
      60 + (withTags ? ActivityKindTags.height + 8 : 0);

  bool _matches(LogInfo log, String query) {
    final kind = ActivityKind.of(log.type);
    if (_filter != null && kind != _filter) return false;
    if (query.isEmpty) return true;
    final entry = ActivityEntry.fromLog(log);
    final text = normaliseForSearch(
      [
        entry.party.name,
        FlutterI18n.translate(context, kind.subtitleKey),
        FlutterI18n.translate(context, kind.labelKey),
        for (final c in entry.cards) c.credential.name,
      ].join(" "),
    );
    return text.contains(query);
  }

  Widget _buildLogEntries(
    BuildContext context,
    List<LogInfo> logEntries,
    bool moreLogsAvailable,
  ) {
    _addPostFrameCallback();
    // The detail pane shows the newest entry until one is picked; it was
    // built before the entries came in, so build it again.
    final firstEntries = _latestEntries.isEmpty && logEntries.isNotEmpty;
    _latestEntries = logEntries;
    if (firstEntries && useHomePanes(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    final local = FlutterI18n.currentLocale(context).toString();
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);

    final query = normaliseForSearch(_query);
    final shown = logEntries.where((e) => _matches(e, query)).toList();
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

    Widget message(String key) => Padding(
      padding: const EdgeInsets.only(top: 32),
      child: TranslatedText(
        key,
        textAlign: TextAlign.center,
        style: palette.body(16).copyWith(color: palette.heading),
      ),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        16,
        padding.top +
            FloatingBarPlacement.topGap(context) +
            _headerHeight(logEntries.isNotEmpty && !tagsInList),
        16,
        padding.bottom + bottomBarSpace(context),
      ),
      children: [
        // In the list column they stay inside it, clear of the pane.
        if (tagsInList && logEntries.isNotEmpty) _tags(clip: true),
        if (logEntries.isEmpty)
          message("activity.empty_placeholder")
        else if (shown.isEmpty && query.isEmpty && _filter != null)
          // Keeps loading older pages while there is more (see
          // _addPostFrameCallback), so this shows only once the log ended.
          moreLogsAvailable
              ? const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: EndOfListIndicator(isLoading: true)),
                )
              : message("activity.filter_empty.${_filter!.name}")
        else if (shown.isEmpty)
          message("activity.no_results")
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
    _scrollController.addListener(_listenToScroll);
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final top = padding.top + FloatingBarPlacement.topGap(context);
    final list = StreamBuilder<HistoryState>(
      stream: _historyRepo.getHistoryState(),
      builder: (context, snapshot) {
        final historyState = snapshot.data;
        final withTags = historyState?.logEntries.isNotEmpty ?? false;
        // Held sideways the tags scroll with the list, under the search
        // field, instead of floating with it.
        final tagsInList = usePhoneLandscape(context);
        // The entries scroll under the search field and the tags; the edge
        // goes away with them when an entry opens.
        return ScrollEdge(
          height: top + _headerHeight(withTags) - 4,
          // Held sideways the search field just floats over the list, with
          // no band under it.
          band: (context, under) => usePhoneLandscape(context)
              ? const SizedBox.shrink()
              : PushAway(
                  direction: PushAwayDirection.up,
                  child: ScrollEdgeBand(under: under),
                ),
          bar: [
            Positioned(
              left: 16,
              right: 16,
              top: top,
              child: PushAway(
                direction: PushAwayDirection.up,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlassSearchField(
                          fieldKey: const Key("activity_search_field"),
                          hintKey: "activity.search_placeholder",
                          controller: _search,
                          onChanged: _onQuery,
                        ),
                        if (withTags && !tagsInList) ...[
                          const SizedBox(height: 8),
                          _tags(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          child: historyState == null
              ? Center(child: LoadingIndicator())
              : _buildLogEntries(
                  context,
                  historyState.logEntries,
                  historyState.moreLogsAvailable,
                ),
        );
      },
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
          : ActivityDetailPane(key: ValueKey(entry.time), logEntry: entry),
    );
  }
}
