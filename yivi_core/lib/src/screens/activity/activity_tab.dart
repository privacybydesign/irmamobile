import "dart:async";
import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../models/activity_query.dart";
import "../../models/log_entry.dart";
import "../../providers/activity_providers.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/pane_selection_provider.dart";
import "../../theme/yivi_motion.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/adaptive_layout.dart";
import "../../util/after_frame.dart";
import "../../util/i18n.dart";
import "../../widgets/corner_badge.dart";
import "../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../widgets/empty_list_message.dart";
import "../../widgets/glass/glass_search_field.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/loading_more_indicator.dart";
import "../../widgets/scroll_edge.dart";
import "../../widgets/tab_layout.dart";
import "../../widgets/title_scroll_edge.dart";
import "../../widgets/yivi_spinner.dart";
import "../home/widgets/home_tab_top.dart";
import "../home/widgets/search_tab_controller.dart";
import "../home/widgets/search_tab_scaffold.dart";
import "activity_detail_screen.dart";
import "activity_entry.dart";
import "activity_filter_sheet.dart";
import "activity_kind_words.dart";
import "activity_options.dart";
import "activity_query_labels.dart";
import "widgets/activity_card.dart";
import "widgets/activity_detail_parts.dart";
import "widgets/activity_query_chips.dart";

part "activity_day_header.dart";

/// The Activity tab: the log, newest first, a white band of rows per day
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

/// The sides of a row of tags or suggestions that runs to the screen's edges.
const _inset = EdgeInsets.symmetric(horizontal: YiviSpace.x16);

/// The height of the row of suggestions under the field while searching.
const double _suggestionRowHeight = 40;

/// The height of the "12 results" line at the top of the log while
/// searching.
const double _liveCountHeight = 28;

class _ActivityTabState extends ConsumerState<ActivityTab> {
  final _scrollController = ScrollController();
  late final _field = SearchTabController(this, onFocus: _focused);

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
  late final _counter = ActivityOptionCounter(ref.read(irmaRepositoryProvider));

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_listenToScroll);
  }

  /// A tap in the field: the search starts; after Enter, it is typing
  /// again.
  void _focused() {
    if (!_searching) {
      _startSearching();
    } else if (_submitted) {
      setState(() => _submitted = false);
      _scheduleCounts();
    }
  }

  @override
  void dispose() {
    _countDelay?.cancel();
    _liveDelay?.cancel();
    _field.dispose();
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
  void _startSearchingInBar() => _field.startInBar(_startSearching);

  /// Ends the search: the log keeps [keep], or (Cancel) goes back to the
  /// question asked before.
  void _endSearching({ActivityQuery? keep}) {
    _liveDelay?.cancel();
    _field.stop();
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
    _field.field.clear();
    setState(() {
      _draft = query;
      _typed = "";
    });
    _field.focus.requestFocus();
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
    final typing = _field.focus.hasFocus;
    setState(() => _draft = query);
    if (typing) _field.focus.requestFocus();
    _showLive(now: true);
    _scheduleCounts();
  }

  /// The draft with what is still typed as words to search.
  ActivityQuery _withTyped(ActivityQuery q, String typed) {
    // "gedeeld met" asks for shared entries; the rest is searched.
    final (kinds, rest) = readKindWords(
      typed,
      ActivityWords.of(context).kindPhrases(),
    );
    if (kinds.isNotEmpty) q = q.copyWith(kinds: {...q.kinds, ...kinds});
    final words = rest.trim();
    if (words.isEmpty) return q;
    final text = q.text.trim();
    return q.copyWith(text: text.isEmpty ? words : "$text $words");
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
    _field.focus.unfocus();
    _showLive(now: true);
  }

  /// The field's clear button: after Enter, with no tags either, the search
  /// ends; otherwise it is typing again.
  void _cleared() {
    if (_submitted && _asked.isEmpty) {
      _endSearching(keep: ActivityQuery.empty);
    } else {
      _field.focus.requestFocus();
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
    if (_searching) _field.focus.unfocus();
    openActivity(context, entry);
  }

  void _loadMoreLogs() => ref.read(activityLogProvider.notifier).loadMore();

  void _addPostFrameCallback() {
    // After list is initially rendered, there might not be enough logs to trigger the scroll controller.
    // In that case, load more logs to fully fill the screen.
    afterFrame(() {
      if (!_scrollController.hasClients ||
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

  /// Everything that could be suggested, by group in the order shown, before
  /// the counts weed out and sort ([activitySuggestions]), each with its
  /// picture and label.
  List<List<_Suggestion>> _candidates(List<PartySummary> parties) {
    final words = ActivityWords.of(context);
    return [
      for (final group in activitySuggestions(
        asked: _asked,
        typed: _typed,
        cards: ref.read(activityCardRefsProvider),
        parties: parties,
        words: words,
      ))
        [for (final o in group) _suggestion(o, words)],
    ];
  }

  _Suggestion _suggestion(ActivityOption o, ActivityWords words) {
    final (leading, title) = switch (o) {
      KindOption(:final kind) => (
        CornerBadge(icon: kind.icon, fill: kind.badge, size: 20, iconSize: 12),
        words.kind(kind),
      ),
      CardOption(:final card) => (
        CredentialCardArt(
          credential: card.art,
          width: 30,
          greyedOut: card.removed,
        ),
        card.name,
      ),
      PartyOption(:final party) => (
        ActivityPartyLogo(party: ActivityParty.of(party.party), size: 22),
        party.party.name,
      ),
      // The full path, as the tag it becomes.
      FieldOption(:final card, :final token) => (
        CredentialCardArt(credential: card.art, width: 30),
        "${card.name} › ${words.field(token)}",
      ),
      ValueOption(:final words) => (
        Icon(
          Icons.badge_outlined,
          size: 18,
          color: YiviPalette.of(context).link,
        ),
        context.tr("activity.query.suggest.value_for", {"text": words}),
      ),
      PeriodOption() => throw StateError("no period suggestions"),
    };
    return _Suggestion(
      key: o.key,
      leading: leading,
      title: title,
      query: o.query,
    );
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
      final all = _candidates(
        ref.read(activityPartiesProvider).value ?? const [],
      ).flattened;
      final counts = await _counter.count({
        for (final s in all) s.key: s.query,
      });
      if (counts == null || !mounted) return;
      setState(() {
        _counts
          ..clear()
          ..addAll(counts);
      });
    });
  }

  /// The row of suggestions under the field (and the tags) while searching.
  Widget? _suggestionRow({bool inset = true}) {
    final suggestions = _suggestions();
    if (suggestions.isEmpty) return null;
    return _sideRow(const Key("activity_suggestions"), _suggestionRowHeight, [
      for (final s in suggestions)
        ActivitySuggestionChip(
          key: Key("activity_suggestion_${s.key}"),
          label: s.title,
          leading: s.leading,
          onTap: () => _pick(s.query),
        ),
    ], padding: inset ? _inset : null);
  }

  /// A row of tags that scrolls sideways.
  Widget _tagRow(List<Widget> chips, {EdgeInsets? padding}) => _sideRow(
    const Key("activity_chips"),
    activityChipHeight,
    chips,
    padding: padding,
  );

  /// [children] in a row [height] high that scrolls sideways, 8 apart;
  /// clipped to the row only when [padding] insets them.
  Widget _sideRow(
    Key key,
    double height,
    List<Widget> children, {
    EdgeInsets? padding,
  }) => SizedBox(
    height: height,
    child: ListView.separated(
      key: key,
      scrollDirection: Axis.horizontal,
      clipBehavior: padding == null ? Clip.none : Clip.hardEdge,
      padding: padding,
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(width: YiviSpace.x8),
      itemBuilder: (_, i) => Center(child: children[i]),
    ),
  );

  /// The search field, in the bar on a phone held upright ([height] 44) or
  /// over the list (48, the field's own height).
  Widget _searchField({double height = 48}) => GlassSearchField(
    fieldKey: const Key("activity_search_field"),
    hintKey: "activity.query.search_hint",
    controller: _field.field,
    focusNode: _field.focus,
    onChanged: _onTyped,
    onSubmitted: _searchText,
    onCleared: _cleared,
    height: height,
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
            spacing: YiviSpace.x2,
            children: [
              for (final kind in ActivityKind.ordered)
                if (q.kinds.contains(kind.logType))
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
          // With the fields asked about: which card each comes from.
          label: activityCardFieldsLabel(context, card, q.fields),
          // Its fields go with it.
          onRemove: () => change(q.withCard(null)),
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
          label: context.tr("activity.query.value_chip", {
            "text": quotedSearch(q.value),
          }),
          onRemove: () => change(q.copyWith(value: "")),
        ),
    ];
  }

  // --------------------------------------------------------------------- list

  /// The log: [header] (a phone's large title, field and tags) from [top],
  /// then per day a header that sticks [pinTop] from the top of the
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
        ? ref.watch(activityPaneEntryProvider)
        : null;

    // A header per day, then its rows.
    final groups = ref.watch(activityDayGroupsProvider);

    final clear = TextLink(
      key: const Key("activity_clear_filters"),
      label: context.tr("activity.query.clear"),
      onPressed: _clearAll,
    );
    final count = state.counts?.total ?? logEntries.length;
    final bandEdge = palette.isDark
        ? BorderSide.none
        : BorderSide(color: palette.divider);
    Widget padded(Widget child) => SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
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
        // days stick.
        SliverPersistentHeader(
          pinned: true,
          delegate: _TopSpace(top: top, pinned: min(pinTop, top)),
        ),
        if (header.isNotEmpty)
          padded(
            Padding(
              padding: const EdgeInsets.only(bottom: YiviSpace.x8),
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
                  delegate: _DayHeader(
                    title: _dayTitle(context, group.first.time, local),
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
                        // The day is in the header.
                        timeOnly: true,
                        onTap: () => _open(entry),
                      );
                    },
                  ),
                ),
              ],
            ),
          // While older activity loads; at the end the list just ends.
          if (moreLogsAvailable)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  top: YiviSpace.x16,
                  bottom: YiviSpace.x16,
                ),
                child: LoadingMoreIndicator(),
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
    final filterButton = YiviIconButton(
      key: const Key("activity_filter_button"),
      icon: CupertinoIcons.slider_horizontal_3,
      label: filterCount == 0
          ? context.tr("activity.query.filter")
          : context.tr("activity.query.filter_active", {
              "count": "$filterCount",
            }),
      count: filterCount,
      onTap: _openFilter,
      look: IconButtonLook.bar,
    );
    final cancel = TextLink(
      key: const Key("activity_search_cancel"),
      label: context.tr("activity.query.cancel"),
      onPressed: _endSearching,
    );
    // Next to the field: Cancel while typing; after Enter the filter, as
    // Cancel makes room for it.
    final fieldAction = AnimatedSwitcher(
      duration: YiviMotion.standard,
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
    final header = <Widget>[
      HomeTabHeader(
        title: const TabLargeTitle("home.nav_bar.activity"),
        field: HomeTabSearchField(
          key: const Key("activity_search_field"),
          hint: context.tr("activity.query.search_hint"),
          onTap: _startSearchingInBar,
        ),
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
                      _tagRow(chips, padding: _inset),
                      const SizedBox(height: YiviSpace.x2),
                    ],
                    ?suggestionRow,
                  ],
                ))
        : chips.isEmpty
        ? null
        : _tagRow(chips, padding: _inset);

    // Next to a pane: the field (and Cancel or the filter) in a row over
    // the log, the tags and while searching the suggestions under it.
    final extrasHeight =
        (rowChips.isEmpty ? 0.0 : activityChipHeight + 8) +
        (suggestionRow == null ? 0.0 : _suggestionRowHeight + 4);
    final paneListTop = SearchTabScaffold.edge(context, extras: extrasHeight);

    final Widget log;
    if (!state.loaded) {
      log = Center(child: YiviSpinner());
    } else if (panes) {
      log = _buildLogEntries(
        context,
        state,
        paneListTop + 4,
        pinTop: paneListTop,
        header: [
          if (chipsScroll && chips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: YiviSpace.x4),
              child: _tagRow(chips),
            ),
        ],
      );
    } else if (_searching) {
      final listTop = HomeTabTop.listTop(
        context,
        below: below == null ? 0 : belowHeight,
      );
      // The days stick right under the band, and continue it.
      log = _buildLogEntries(
        context,
        state,
        listTop,
        pinTop: HomeTabTop.bandBottom(
          context,
          below: below == null ? 0 : belowHeight,
        ),
        joinBar: true,
      );
    } else {
      log = _buildLogEntries(
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
      );
    }

    final entry = panes ? ref.watch(activityPaneEntryProvider) : null;
    return SearchTabScaffold(
      searching: _searching,
      title: context.tr("home.nav_bar.activity"),
      searchLabel: context.tr("activity.query.search_hint"),
      searchButtonKey: const Key("activity_search_button"),
      onStartSearch: _startSearchingInBar,
      field: (height) => _searchField(height: height),
      barAction: fieldAction,
      rowAction: fieldAction,
      trailing: filterButton,
      // The tags pin under the bar as they scroll up to it; while
      // searching the tags and the suggestions are there at once.
      below: below,
      belowHeight: belowHeight,
      rowExtras: [
        if (rowChips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: YiviSpace.x8),
            child: _tagRow(rowChips),
          ),
        if (suggestionRow != null)
          Padding(
            padding: const EdgeInsets.only(top: YiviSpace.x4),
            child: suggestionRow,
          ),
      ],
      rowExtrasHeight: extrasHeight,
      list: log,
      detail: entry == null
          ? null
          : ActivityDetailPane(key: ValueKey(logKey(entry)), logEntry: entry),
    );
  }
}

/// The header of the day of [time]: "Today", "Yesterday", or the weekday
/// and date ("Monday 26 October"), with the year when it is not this one.
String _dayTitle(BuildContext context, DateTime time, String locale) {
  final day = time.toLocal();
  switch (activityDaysAgo(day)) {
    case 0:
      return context.tr("activity.ago.today");
    case 1:
      return context.tr("activity.yesterday");
  }
  final pattern = day.year == DateTime.now().year
      ? "EEEE d MMMM"
      : "EEEE d MMMM y";
  final text = DateFormat(pattern, locale).format(day);
  // "zaterdag 17 oktober": only the first letter up, the month as it is.
  return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
