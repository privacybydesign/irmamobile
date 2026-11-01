import "dart:async";
import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../providers/activity_providers.dart";
import "../../providers/credentials_search.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/pane_selection_provider.dart";
import "../../providers/schemaless_credentials_list_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../util/after_frame.dart";
import "../../util/string.dart";
import "../../widgets/corner_badge.dart";
import "../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../widgets/empty_list_message.dart";
import "../../widgets/end_of_list_indicator.dart";
import "../../widgets/glass/floating_bar_placement.dart";
import "../../widgets/glass/glass_search_field.dart";
import "../../widgets/glass/home_tab_top.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/glass/round_icon_button.dart";
import "../../widgets/glass/scroll_edge.dart";
import "../../widgets/glass/search_scroll_edge.dart";
import "../../widgets/glass/title_scroll_edge.dart";
import "../../widgets/loading_indicator.dart";
import "../../widgets/two_pane.dart";
import "activity_detail_screen.dart";
import "activity_entry.dart";
import "activity_filter_sheet.dart";
import "activity_query.dart";
import "activity_query_labels.dart";
import "widgets/activity_card.dart";
import "widgets/activity_detail_parts.dart";
import "widgets/activity_query_chips.dart";

/// The Activity tab: the log, newest first, a white band of rows per month
/// under a header that sticks under the bar. irmago does the asking.
///
/// Searching, the log itself shows what the question so far finds: its
/// tags sit in a row under the field (each with a cross), and a row of
/// suggestions under them adds one more (what happened, a card or its
/// fields, a party). Suggestions only narrow the question and never lead to
/// nothing. Enter keeps the question, Cancel goes back to the one before.
/// The filter sheet builds a whole question; what is asked shows as tags
/// under the field.
class ActivityTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

/// One suggestion while searching: picking it asks [query].
class _Suggestion {
  final String key;
  final Widget? leading;
  final String title;
  final ActivityQuery query;

  const _Suggestion({
    required this.key,
    required this.title,
    required this.query,
    this.leading,
  });
}

/// The height of the row of suggestions under the field while searching.
const double _suggestionRowHeight = 40;

/// The height of the "12 results" line at the top of the log while
/// searching.
const double _liveCountHeight = 28;

class _ActivityTabState extends ConsumerState<ActivityTab> {
  final _scrollController = ScrollController();
  final _search = TextEditingController();
  final _focus = FocusNode();

  /// Whether a search is on. It starts when the field gets focus and ends
  /// on Cancel, or once nothing is typed or tagged any more after Enter;
  /// not when the field loses focus.
  bool _searching = false;

  /// Enter pressed: the field stays up in the bar with the typed words, the
  /// keyboard and the suggestions go, and the filter takes Cancel's place.
  /// Back in the field, it is typing again.
  bool _submitted = false;
  String _typed = "";

  /// The question asked before searching: Cancel goes back to it.
  ActivityQuery _before = ActivityQuery.empty;

  /// The question being built while searching: the applied one at the
  /// start, a tag more with each pick. The log shows what it finds with
  /// the typed words.
  ActivityQuery? _draft;
  Timer? _liveDelay;

  /// How many entries each suggestion would leave: those with none go.
  final _counts = <String, int>{};
  Timer? _countDelay;
  var _countGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_listenToScroll);
    _focus.addListener(() {
      if (!_focus.hasFocus) return;
      if (!_searching) {
        _startSearching();
      } else if (_submitted) {
        setState(() => _submitted = false);
        _scheduleCounts();
      }
    });
  }

  @override
  void dispose() {
    _countDelay?.cancel();
    _liveDelay?.cancel();
    _search.dispose();
    _focus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ActivityQuery get _query => ref.read(activityLogProvider).filter;

  /// Searching and not yet past Enter: Cancel, the suggestions, the live
  /// count.
  bool get _typing => _searching && !_submitted;

  /// What the suggestions build on: the draft while searching.
  ActivityQuery get _asked => _draft ?? _query;

  void _ask(ActivityQuery query) {
    ref.read(activityLogProvider.notifier).setFilter(query);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _startSearching() {
    setState(() {
      _searching = true;
      _submitted = false;
      _before = _query;
      _draft = _query;
    });
    _scheduleCounts();
  }

  /// The field under the large title, or the bar's search button: the
  /// search, with the field up in the bar and the keyboard up.
  void _startSearchingInBar() {
    _startSearching();
    afterFrame(() {
      if (mounted) _focus.requestFocus();
    });
  }

  /// Ends the search: the log keeps [keep], or (Cancel) goes back to the
  /// question asked before.
  void _endSearching({ActivityQuery? keep}) {
    _liveDelay?.cancel();
    _search.clear();
    _focus.unfocus();
    final before = _before;
    setState(() {
      _searching = false;
      _submitted = false;
      _typed = "";
      _draft = null;
    });
    _ask(keep ?? before);
  }

  /// The log shows what the draft and the typed words find, a moment
  /// after typing stops (a tag at once).
  void _showLive({bool now = false}) {
    _liveDelay?.cancel();
    void show() {
      if (!mounted || !_searching) return;
      _ask(_withTyped(_asked, _typed));
    }

    if (now) {
      show();
    } else {
      _liveDelay = Timer(const Duration(milliseconds: 150), show);
    }
  }

  /// A suggestion: a tag more on the draft. The field empties and keeps the
  /// keyboard, to add another.
  void _pick(ActivityQuery query) {
    _search.clear();
    setState(() {
      _draft = query;
      _typed = "";
    });
    _focus.requestFocus();
    _showLive(now: true);
    _scheduleCounts();
  }

  /// A tag's cross while searching: the draft without it. The keyboard
  /// stays if it was up. After Enter, with nothing left asked, the search
  /// ends.
  void _changeDraft(ActivityQuery query) {
    if (_submitted && query.isEmpty && _typed.trim().isEmpty) {
      _endSearching(keep: ActivityQuery.empty);
      return;
    }
    final typing = _focus.hasFocus;
    setState(() => _draft = query);
    if (typing) _focus.requestFocus();
    _showLive(now: true);
    _scheduleCounts();
  }

  /// The draft with what is still typed as words to search.
  ActivityQuery _withTyped(ActivityQuery q, String typed) {
    final words = typed.trim();
    if (words.isEmpty) return q;
    final text = q.text.trim();
    return q.copyWith(text: text.isEmpty ? words : "$text $words");
  }

  /// The draft with the typed words to find in the data alone.
  ActivityQuery _withValue(ActivityQuery q, String typed) {
    final words = typed.trim();
    final value = q.value.trim();
    return q.copyWith(value: value.isEmpty ? words : "$value $words");
  }

  /// Enter: the log shows what the draft and the typed words find, and the
  /// field stays with them; with nothing asked, the search ends.
  void _searchText(String text) {
    if (_asked.isEmpty && text.trim().isEmpty) {
      _endSearching(keep: ActivityQuery.empty);
      return;
    }
    _countDelay?.cancel();
    setState(() {
      _typed = text;
      _submitted = true;
    });
    _focus.unfocus();
    _showLive(now: true);
  }

  /// The field's clear button: after Enter, with no tags either, the search
  /// ends; otherwise it is typing again.
  void _cleared() {
    if (_submitted && _asked.isEmpty) {
      _endSearching(keep: ActivityQuery.empty);
    } else {
      _focus.requestFocus();
    }
  }

  void _onTyped(String text) {
    setState(() => _typed = text);
    _showLive();
    _scheduleCounts();
  }

  Future<void> _openFilter() async {
    final next = await showActivityFilterSheet(context, _query);
    if (next == null || !mounted) return;
    if (!_searching) return _ask(next);
    // The typed words stay in the field, not in the draft.
    final draft = next.copyWith(text: _asked.text);
    if (draft.isEmpty && _typed.trim().isEmpty) {
      return _endSearching(keep: ActivityQuery.empty);
    }
    setState(() => _draft = draft);
    _showLive(now: true);
  }

  /// "Clear": nothing asked, and no search any more.
  void _clearAll() => _searching
      ? _endSearching(keep: ActivityQuery.empty)
      : _ask(ActivityQuery.empty);

  /// A row: its details. While searching the keyboard goes first, and
  /// stays down when coming back.
  void _open(LogInfo entry) {
    if (_searching) _focus.unfocus();
    openActivity(context, entry);
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
    if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <
            80) {
      _loadMoreLogs();
    }
  }

  // ---------------------------------------------------------------- suggestions

  List<ActivityCardRef> get _cards => [
    for (final c in ref.read(walletCardsProvider)) ActivityCardRef.of(c),
    ...?ref.read(removedCardTypesProvider).value,
  ];

  /// Everything that could be suggested, by group in the order shown, before
  /// the counts weed out and sort. Only what narrows the question: no kinds
  /// once one is picked, no parties once one is, and once a card is picked,
  /// its fields instead of the cards (after the parties). While typing, what
  /// has the typed text in its name, and last the typed words to find in
  /// the data alone.
  List<List<_Suggestion>> _candidates(List<PartySummary> parties) {
    final q = _asked;
    final typed = normaliseForSearch(_typed.trim());
    bool hit(String s) =>
        typed.isEmpty || normaliseForSearch(s).contains(typed);
    final card = q.card;

    final kinds = [
      if (q.kinds.isEmpty)
        for (final kind in activityKindOrder)
          if (hit(FlutterI18n.translate(context, kind.labelKey)))
            _Suggestion(
              key: "kind:${kind.name}",
              leading: CornerBadge(
                icon: kind.icon,
                fill: kind.badge,
                size: 20,
                iconSize: 12,
              ),
              title: FlutterI18n.translate(context, kind.labelKey),
              query: q.copyWith(kinds: {logTypeOf(kind)}),
            ),
    ];
    final cards = [
      if (card == null)
        for (final c in _cards)
          if (hit(c.name))
            _Suggestion(
              key: "card:${c.key}",
              leading: CredentialCardArt(
                credential: c.art,
                width: 30,
                greyedOut: c.removed,
              ),
              title: c.name,
              query: q.withCard(c),
            ),
    ];
    final partyHits = [
      if (q.party == null)
        for (final p in parties)
          if (hit(p.party.name))
            _Suggestion(
              key: "party:${p.key}",
              leading: ActivityPartyLogo(
                party: ActivityParty.of(p.party),
                size: 22,
              ),
              title: p.party.name,
              query: q.copyWith(party: () => p),
            ),
    ];
    // The fields of the card asked about (picked fields join: either one);
    // while typing with no card asked, those of every card that match,
    // each asking about its card too.
    final fieldCards = card != null
        ? [card]
        : typed.isEmpty
        ? const <ActivityCardRef>[]
        : _cards;
    final fields = <_Suggestion>[
      for (final c in fieldCards)
        if (!c.removed)
          for (final g in claimTokenGroups(c.art.attributes))
            for (final t in g.tokens)
              if (!q.fields.contains(t) && hit(claimTokenLabel(context, t)))
                _Suggestion(
                  key: "field:${c.key}:${t.key}",
                  leading: card == null
                      ? CredentialCardArt(credential: c.art, width: 30)
                      : null,
                  title: claimTokenLabel(context, t),
                  query: card == null
                      ? q.withCard(c).copyWith(fields: [t])
                      : q.copyWith(fields: {...q.fields, t}.toList()),
                ),
    ];
    final words = _typed.trim();
    return [
      kinds,
      if (card == null) ...[
        cards,
        partyHits,
        fields,
      ] else ...[
        partyHits,
        fields,
      ],
      if (words.isNotEmpty)
        [
          _Suggestion(
            key: "value",
            leading: Icon(
              Icons.badge_outlined,
              size: 18,
              color: YiviPalette.of(context).link,
            ),
            title: FlutterI18n.translate(
              context,
              "activity.query.suggest.value_for",
              translationParams: {"text": words},
            ),
            query: _withValue(_asked, words),
          ),
        ],
    ];
  }

  /// The suggestions in one row: per group those that leave something, the
  /// most found first, a few per group (more while typing).
  List<_Suggestion> _suggestions() {
    final take = _typed.trim().isEmpty ? 4 : 6;
    return [
      for (final group in _candidates(
        ref.watch(activityPartiesProvider).value ?? const [],
      ))
        ...() {
          final left = group.where((s) => _counts[s.key] != 0).toList();
          // Sorted once every count is in: no shuffling while they come.
          if (left.every((s) => _counts.containsKey(s.key))) {
            mergeSort(
              left,
              compare: (a, b) => _counts[b.key]!.compareTo(_counts[a.key]!),
            );
          }
          return left.take(take);
        }(),
    ];
  }

  /// Counts what each suggestion would leave, a moment after typing stops.
  void _scheduleCounts() {
    _countDelay?.cancel();
    _countDelay = Timer(const Duration(milliseconds: 150), () async {
      if (!mounted || !_searching) return;
      final generation = ++_countGeneration;
      final all = _candidates(
        ref.read(activityPartiesProvider).value ?? const [],
      ).flattened.toList();
      List<int> counts;
      try {
        counts = await ref.read(irmaRepositoryProvider).countLogs([
          for (final s in all) s.query.toLogFilter(),
        ]);
      } catch (_) {
        return;
      }
      if (!mounted || generation != _countGeneration) return;
      setState(() {
        _counts.clear();
        for (final (i, s) in all.indexed) {
          if (i < counts.length) _counts[s.key] = counts[i];
        }
      });
    });
  }

  /// The row of suggestions under the field (and the tags) while searching.
  Widget? _suggestionRow({bool inset = true}) {
    final suggestions = _suggestions();
    if (suggestions.isEmpty) return null;
    return SizedBox(
      height: _suggestionRowHeight,
      child: ListView.separated(
        key: const Key("activity_suggestions"),
        scrollDirection: Axis.horizontal,
        clipBehavior: inset ? Clip.hardEdge : Clip.none,
        padding: inset ? const EdgeInsets.symmetric(horizontal: 16) : null,
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = suggestions[i];
          return Center(
            child: ActivitySuggestionChip(
              key: Key("activity_suggestion_${s.key}"),
              label: s.title,
              leading: s.leading,
              onTap: () => _pick(s.query),
            ),
          );
        },
      ),
    );
  }

  /// A row of tags that scrolls sideways.
  Widget _tagRow(List<Widget> chips, {EdgeInsets? padding}) => SizedBox(
    height: activityChipHeight,
    child: ListView.separated(
      key: const Key("activity_chips"),
      scrollDirection: Axis.horizontal,
      clipBehavior: padding == null ? Clip.none : Clip.hardEdge,
      padding: padding,
      itemCount: chips.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) => Center(child: chips[i]),
    ),
  );

  // -------------------------------------------------------------------- chips

  /// What is asked, one chip per filter, each with a cross to take it off:
  /// the applied question, or while searching the draft.
  List<Widget> _chips(ActivityQuery q) {
    final card = q.card;
    final change = _searching ? _changeDraft : _ask;
    return [
      if (q.kinds.isNotEmpty)
        ActivityFacetChip(
          key: const Key("activity_chip_kinds"),
          // The badge of each kind, as on the rows.
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 2,
            children: [
              for (final kind in activityKindOrder)
                if (q.kinds.contains(logTypeOf(kind)))
                  CornerBadge(
                    icon: kind.icon,
                    fill: kind.badge,
                    size: 24,
                    iconSize: 14,
                  ),
            ],
          ),
          label: activityKindsLabel(context, q.kinds),
          onRemove: () => change(q.copyWith(kinds: {})),
        ),
      if (card != null)
        ActivityFacetChip(
          key: const Key("activity_chip_card"),
          leading: CredentialCardArt(
            credential: card.art,
            width: 26,
            greyedOut: card.removed,
          ),
          label: card.name,
          // Its fields go with it.
          onRemove: () => change(q.withCard(null)),
        ),
      // Each field asked about, a tag of its own.
      for (final t in q.fields)
        ActivityFacetChip(
          key: Key("activity_chip_field_${t.key}"),
          label: claimTokenLabel(context, t),
          onRemove: () => change(q.copyWith(fields: [...q.fields]..remove(t))),
        ),
      if (q.party != null)
        ActivityFacetChip(
          key: const Key("activity_chip_party"),
          leading: ActivityPartyLogo(
            party: ActivityParty.of(q.party!.party),
            size: 24,
          ),
          label: q.party!.party.name,
          onRemove: () => change(q.copyWith(party: () => null)),
        ),
      if (q.period != ActivityPeriod.all)
        ActivityFacetChip(
          key: const Key("activity_chip_period"),
          leading: Icon(
            CupertinoIcons.calendar,
            size: 18,
            color: YiviPalette.of(context).onLink,
          ),
          label: activityPeriodLabel(context, q),
          onRemove: () => change(
            q.copyWith(
              period: ActivityPeriod.all,
              from: () => null,
              to: () => null,
            ),
          ),
        ),
      if (q.text.trim().isNotEmpty)
        ActivityFacetChip(
          key: const Key("activity_chip_text"),
          label: quotedSearch(q.text),
          onRemove: () => change(q.copyWith(text: "")),
        ),
      if (q.value.trim().isNotEmpty)
        ActivityFacetChip(
          key: const Key("activity_chip_value"),
          label: FlutterI18n.translate(
            context,
            "activity.query.value_chip",
            translationParams: {"text": quotedSearch(q.value)},
          ),
          onRemove: () => change(q.copyWith(value: "")),
        ),
    ];
  }

  // --------------------------------------------------------------------- list

  /// The log: [header] (a phone's large title, field and tags) from [top],
  /// then per month a header that sticks [pinTop] from the top of the
  /// screen (under the bar and what is pinned under it) and its rows on a
  /// white band.
  Widget _buildLogEntries(
    BuildContext context,
    ActivityLogState state,
    double top, {
    required double pinTop,
    List<Widget> header = const [],
    bool joinBar = false,
  }) {
    final logEntries = state.entries;
    final moreLogsAvailable = state.moreAvailable;
    final query = state.filter;
    _addPostFrameCallback();
    final local = FlutterI18n.currentLocale(context).toString();
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    // The entry in the detail pane: the picked one, or the newest.
    final open = useHomePanes(context)
        ? ref.watch(selectedActivityProvider) ?? logEntries.firstOrNull
        : null;

    // A header per month, then its rows.
    final groups = <List<LogInfo>>[];
    for (final entry in logEntries) {
      final last = groups.lastOrNull;
      if (last == null ||
          last.last.time.toLocal().month != entry.time.toLocal().month ||
          last.last.time.toLocal().year != entry.time.toLocal().year) {
        groups.add([entry]);
      } else {
        last.add(entry);
      }
    }

    final clear = TextLink(
      key: const Key("activity_clear_filters"),
      label: FlutterI18n.translate(context, "activity.query.clear"),
      onPressed: _clearAll,
    );
    final count = state.counts?.total ?? logEntries.length;
    final bandEdge = palette.isDark
        ? BorderSide.none
        : BorderSide(color: palette.divider);
    Widget padded(Widget child) => SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      ),
    );

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      // Searching, scrolling the results puts the keyboard away.
      keyboardDismissBehavior: _searching
          ? ScrollViewKeyboardDismissBehavior.onDrag
          : ScrollViewKeyboardDismissBehavior.manual,
      slivers: [
        // The space above the list; scrolled, what stays of it is where the
        // months stick.
        SliverPersistentHeader(
          pinned: true,
          delegate: _TopSpace(top: top, pinned: min(pinTop, top)),
        ),
        if (header.isNotEmpty)
          padded(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: HomeTabTop.fieldGap,
                children: header,
              ),
            ),
          ),
        if (_typing)
          padded(
            SizedBox(
              height: _liveCountHeight,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  activityResults(context, count),
                  key: const Key("activity_result_count"),
                  style: palette
                      .body(13)
                      .copyWith(color: palette.secondaryText),
                ),
              ),
            ),
          )
        else if (!query.isEmpty && logEntries.isNotEmpty)
          padded(
            Row(
              children: [
                Expanded(
                  child: Text(
                    activityResults(context, count),
                    key: const Key("activity_result_count"),
                    style: palette.body(14).copyWith(color: palette.heading),
                  ),
                ),
                clear,
              ],
            ),
          ),
        if (logEntries.isEmpty && !query.isEmpty) ...[
          padded(const EmptyListMessage("activity.query.none")),
          if (!_typing) padded(Center(child: clear)),
        ] else if (logEntries.isEmpty)
          padded(const EmptyListMessage("activity.empty_placeholder"))
        else ...[
          for (final group in groups)
            SliverMainAxisGroup(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _MonthHeader(
                    title: DateFormat(
                      group.first.time.toLocal().year == DateTime.now().year
                          ? "MMMM"
                          : "MMMM y",
                      local,
                    ).format(group.first.time.toLocal()).toCapitalized(),
                    palette: palette,
                    textScaler: MediaQuery.textScalerOf(context),
                    joinsBar: joinBar,
                  ),
                ),
                DecoratedSliver(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    border: Border(top: bandEdge, bottom: bandEdge),
                  ),
                  sliver: SliverList.builder(
                    itemCount: group.length,
                    itemBuilder: (context, i) {
                      final entry = group[i];
                      return ActivityCard(
                        key: ValueKey(logKey(entry)),
                        logEntry: entry,
                        focusCard: query.card,
                        selected: open != null && sameLog(open, entry),
                        divider: i < group.length - 1,
                        onTap: () => _open(entry),
                      );
                    },
                  ),
                ),
              ],
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: EndOfListIndicator(isLoading: moreLogsAvailable),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: SizedBox(
            height: _searching
                ? max(
                    MediaQuery.viewInsetsOf(context).bottom,
                    padding.bottom + bottomBarSpace(context),
                  )
                : padding.bottom + bottomBarSpace(context),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final top = padding.top + FloatingBarPlacement.topGap(context);
    final state = ref.watch(activityLogProvider);
    final query = state.filter;
    final chips = _chips(_searching ? _asked : query);
    final panes = useHomePanes(context);
    final suggestionRow = _typing ? _suggestionRow(inset: !panes) : null;
    // A phone held sideways has little height: there the tags scroll with
    // the log, and only stay at the top while searching.
    final chipsScroll = usePhoneLandscape(context) && !_searching;
    final rowChips = chipsScroll ? const <Widget>[] : chips;

    final filterCount = query.isEmpty ? 0 : query.facetCount;
    final filterButton = RoundIconButton(
      key: const Key("activity_filter_button"),
      icon: CupertinoIcons.slider_horizontal_3,
      label: filterCount == 0
          ? FlutterI18n.translate(context, "activity.query.filter")
          : FlutterI18n.translate(
              context,
              "activity.query.filter_active",
              translationParams: {"count": "$filterCount"},
            ),
      count: filterCount,
      onTap: _openFilter,
    );
    final cancel = TextButton(
      key: const Key("activity_search_cancel"),
      // Blue, as a plain action next to a field.
      style: TextButton.styleFrom(foregroundColor: palette.link),
      onPressed: _endSearching,
      child: Text(FlutterI18n.translate(context, "activity.query.cancel")),
    );
    // Next to the field: Cancel while typing; after Enter the filter, as
    // Cancel makes room for it.
    final fieldAction = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [...previous, ?current],
      ),
      // Its width grows and shrinks unclipped: the filter's count stands
      // out over its corner.
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) => Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        ),
      ),
      child: _typing ? cancel : filterButton,
    );

    // A phone held upright: the large title, the field and the tags at the
    // top of the log, scrolling under a solid bar with the filter at its
    // right, as on the Data tab.
    if (!panes) {
      final header = <Widget>[
        const TabLargeTitle("home.nav_bar.activity"),
        HomeTabSearchField(
          key: const Key("activity_search_field"),
          hint: FlutterI18n.translate(context, "activity.query.search_hint"),
          onTap: _startSearchingInBar,
        ),
        if (chips.isNotEmpty) _tagRow(chips),
      ];
      // Under the bar while searching: the tags, then the suggestions.
      final belowHeight = _searching
          ? (chips.isEmpty ? 0.0 : activityChipHeight + 2) +
                (suggestionRow == null ? 0.0 : _suggestionRowHeight)
          : activityChipHeight;
      final below = _searching
          ? (belowHeight == 0
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (chips.isNotEmpty) ...[
                        _tagRow(
                          chips,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        const SizedBox(height: 2),
                      ],
                      ?suggestionRow,
                    ],
                  ))
          : chips.isEmpty
          ? null
          : _tagRow(chips, padding: const EdgeInsets.symmetric(horizontal: 16));
      final listTop = HomeTabTop.listTop(
        context,
        below: below == null ? 0 : belowHeight,
      );
      // The months stick right under the band, and continue it.
      final searchPinTop = HomeTabTop.bandBottom(
        context,
        below: below == null ? 0 : belowHeight,
      );
      return Scaffold(
        backgroundColor: palette.background,
        // The keyboard covers the tab; the list keeps clear of it itself.
        resizeToAvoidBottomInset: false,
        body: HomeTabTop(
          title: FlutterI18n.translate(context, "home.nav_bar.activity"),
          searching: _searching,
          searchRow: Row(
            spacing: 4,
            children: [
              Expanded(
                child: GlassSearchField(
                  fieldKey: const Key("activity_search_field"),
                  hintKey: "activity.query.search_hint",
                  controller: _search,
                  focusNode: _focus,
                  onChanged: _onTyped,
                  onSubmitted: _searchText,
                  onCleared: _cleared,
                  height: 44,
                ),
              ),
              fieldAction,
            ],
          ),
          // The tags pin under the bar as they scroll up to it; while
          // searching the tags and the suggestions are there at once.
          below: below,
          belowHeight: belowHeight,
          searchButtonKey: const Key("activity_search_button"),
          searchLabel: FlutterI18n.translate(
            context,
            "activity.query.search_hint",
          ),
          onSearch: _startSearchingInBar,
          trailing: filterButton,
          othersDrop: false,
          child: !state.loaded
              ? Center(child: LoadingIndicator())
              : _searching
              ? _buildLogEntries(
                  context,
                  state,
                  listTop,
                  pinTop: searchPinTop,
                  joinBar: true,
                )
              : _buildLogEntries(
                  context,
                  state,
                  HomeTabTop.titleTop(context),
                  // Under the bar, and under the tags once they pin there.
                  pinTop: HomeTabTop.bandBottom(
                    context,
                    below: chips.isEmpty ? 0 : activityChipHeight,
                  ),
                  header: header,
                  joinBar: true,
                ),
        ),
      );
    }

    // The field (and Cancel or the filter), the tags, and while searching
    // the suggestions.
    final row = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: GlassSearchField(
                fieldKey: const Key("activity_search_field"),
                hintKey: "activity.query.search_hint",
                controller: _search,
                focusNode: _focus,
                onChanged: _onTyped,
                onSubmitted: _searchText,
                onCleared: _cleared,
              ),
            ),
            fieldAction,
          ],
        ),
        if (rowChips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _tagRow(rowChips),
          ),
        if (suggestionRow != null)
          Padding(padding: const EdgeInsets.only(top: 4), child: suggestionRow),
      ],
    );
    final headerHeight =
        60.0 +
        (rowChips.isEmpty ? 0 : activityChipHeight + 8) +
        (suggestionRow == null ? 0 : _suggestionRowHeight + 4);
    final listTop = top + headerHeight;
    final list = SearchScrollEdge(
      height: listTop - 4,
      top: top,
      row: row,
      child: !state.loaded
          ? Center(child: LoadingIndicator())
          : _buildLogEntries(
              context,
              state,
              listTop,
              pinTop: listTop - 4,
              header: [
                if (chipsScroll && chips.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _tagRow(chips),
                  ),
              ],
            ),
    );

    return Scaffold(
      backgroundColor: palette.background,
      resizeToAvoidBottomInset: false,
      body: _withDetailPane(list),
    );
  }

  /// The tablet layout: the activity next to the details of the picked
  /// entry (the newest until the user picks one).
  Widget _withDetailPane(Widget list) {
    final entry =
        ref.watch(selectedActivityProvider) ??
        ref.watch(activityLogProvider).entries.firstOrNull;
    return TwoPane(
      list: list,
      detail: entry == null
          ? null
          : ActivityDetailPane(key: ValueKey(logKey(entry)), logEntry: entry),
    );
  }
}

/// The space above the log: [top] high, and scrolled, [pinned] of it stays
/// (under the bar), so the month headers stick under it.
class _TopSpace extends SliverPersistentHeaderDelegate {
  final double top;
  final double pinned;

  const _TopSpace({required this.top, required this.pinned});

  @override
  double get maxExtent => top;

  @override
  double get minExtent => pinned;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      const SizedBox.expand();

  @override
  bool shouldRebuild(_TopSpace old) => old.top != top || old.pinned != pinned;
}

/// A month's header, on the page colour: it sticks under the bar while
/// its rows scroll, and the next month's pushes it away. With [joinsBar],
/// as soon as a row goes under it, it takes the colour of the bar's band
/// and a line of its own, under the bar's line.
class _MonthHeader extends SliverPersistentHeaderDelegate {
  final String title;
  final YiviPalette palette;
  final TextScaler textScaler;
  final bool joinsBar;

  const _MonthHeader({
    required this.title,
    required this.palette,
    required this.textScaler,
    this.joinsBar = false,
  });

  double get _height => 18 + textScaler.scale(24) + 8;

  @override
  double get maxExtent => _height;

  @override
  double get minExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    // A row under it, from its first point: held under the bar
    // ([overlaps]) is when its first row starts to go under it. In a month's
    // group [shrinkOffset] only grows once that row has gone all the way.
    final under = joinsBar && (overlaps || shrinkOffset > 0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: under ? ScrollEdgeBand.fill(palette) : palette.background,
        border: under ? Border(bottom: ScrollEdgeBand.lineSide(context)) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Semantics(
          header: true,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: palette.display(18).copyWith(height: 24 / 18),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_MonthHeader old) =>
      old.title != title ||
      old.palette != palette ||
      old.textScaler != textScaler ||
      old.joinsBar != joinsBar;
}
