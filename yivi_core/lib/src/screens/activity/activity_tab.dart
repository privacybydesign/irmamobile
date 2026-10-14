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
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../util/string.dart";
import "../../widgets/end_of_list_indicator.dart";
import "../../widgets/glass/glass_search_field.dart";
import "../../widgets/loading_indicator.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/two_pane.dart";
import "activity_detail_screen.dart";
import "history_repository.dart";
import "widgets/activity_card.dart";

class ActivityTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<ActivityTab> {
  late final HistoryRepository _historyRepo;
  final _scrollController = ScrollController();
  late StreamSubscription _repoStateSubscription;
  String _query = "";

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
    super.dispose();
  }

  void _loadInitialLogs() {
    IrmaRepositoryProvider.of(context).bridgedDispatch(LoadLogsEvent(max: 10));
  }

  Future<void> _loadMoreLogs() async {
    final historyState = await _historyRepo.getHistoryState().first;
    if (historyState.moreLogsAvailable && !historyState.loading && mounted) {
      IrmaRepositoryProvider.of(context).bridgedDispatch(
        LoadLogsEvent(before: historyState.logEntries.last.time, max: 10),
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

  Widget _buildLogEntries(
    BuildContext context,
    List<LogInfo> logEntries,
    bool moreLogsAvailable,
  ) {
    _addPostFrameCallback();
    _latestEntries = logEntries;
    final local = FlutterI18n.currentLocale(context).toString();
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);

    final query = normaliseForSearch(_query);
    final shown = query.isEmpty
        ? logEntries
        : logEntries.where((entry) {
            final summary = activitySummary(entry);
            final text = normaliseForSearch(
              "${summary.title} ${FlutterI18n.translate(context, summary.subtitleKey)}",
            );
            return text.contains(query);
          }).toList();

    // One rounded group per month.
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
        padding.top + 76,
        16,
        padding.bottom + bottomBarSpace(context),
      ),
      children: [
        if (logEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: TranslatedText(
              "activity.empty_placeholder",
              textAlign: TextAlign.center,
              style: palette.body(16).copyWith(color: palette.heading),
            ),
          )
        else if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: TranslatedText(
              "activity.no_results",
              textAlign: TextAlign.center,
              style: palette.body(16).copyWith(color: palette.heading),
            ),
          )
        else ...[
          for (final group in groups) ...[
            Padding(
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
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: palette.surface,
                  shape: const RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  shadows: const [
                    BoxShadow(
                      color: Color(0x17000000),
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRSuperellipse(
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  child: Column(
                    children: [
                      for (final (i, entry) in group.indexed)
                        ActivityCard(logEntry: entry, showDivider: i > 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: EndOfListIndicator(isLoading: moreLogsAvailable),
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
    final list = Stack(
      children: [
        Positioned.fill(
          child: StreamBuilder<HistoryState>(
            stream: _historyRepo.getHistoryState(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: LoadingIndicator());
              }
              final historyState = snapshot.data!;
              return _buildLogEntries(
                context,
                historyState.logEntries,
                historyState.moreLogsAvailable,
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: padding.top + 72,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.background,
                    palette.background.withValues(alpha: 0),
                  ],
                  stops: const [0.4, 1],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: padding.top + 16,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: GlassSearchField(
                fieldKey: const Key("activity_search_field"),
                hintKey: "activity.search_placeholder",
                onChanged: (q) => setState(() => _query = q),
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: palette.background,
      body: isExpandedLayout(context) ? _withDetailPane(list) : list,
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
