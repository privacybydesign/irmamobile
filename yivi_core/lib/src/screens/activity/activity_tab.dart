import "dart:async";

import "package:collection/collection.dart";
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
import "../../widgets/glass/glass_group.dart";
import "../../widgets/glass/glass_search_field.dart";
import "../../widgets/glass/glass_surface.dart";
import "../../widgets/glass/search_scroll_edge.dart";
import "../../widgets/loading_indicator.dart";
import "../../widgets/two_pane.dart";
import "../data/wallet/wallet_transition.dart";
import "activity_detail_screen.dart";
import "activity_entry.dart";
import "activity_filter_sheet.dart";
import "activity_query.dart";
import "activity_query_labels.dart";
import "widgets/activity_card.dart";
import "widgets/activity_detail_parts.dart";
import "widgets/activity_query_chips.dart";

/// The Activity tab: the log, newest first, grouped by month. irmago does
/// the asking: the search field suggests what to filter on (what happened,
/// cards, parties, their fields) or searches the typed words, the filter
/// sheet builds a whole question, and what is asked shows as chips under the
/// field, each with a cross to take it off. The field, the filter button and
/// the chips stay at the top while the list scrolls.
class ActivityTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

/// One suggestion while searching: picking it asks [query].
class _Suggestion {
  final String key;
  final Widget leading;
  final String title;
  final String subtitle;
  final ActivityQuery query;

  const _Suggestion({
    required this.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.query,
  });
}

class _ActivityTabState extends ConsumerState<ActivityTab> {
  final _scrollController = ScrollController();
  final _search = TextEditingController();
  final _focus = FocusNode();

  /// Whether the suggestions show. It starts when the field gets focus and
  /// ends on a pick, a search or Cancel, not when the field loses focus: a
  /// tap on a suggestion takes the focus first.
  bool _searching = false;
  String _typed = "";

  /// How many entries each suggestion would leave: those with none fade.
  final _counts = <String, int>{};
  Timer? _countDelay;
  var _countGeneration = 0;

  /// The entries shown last, for the default of the tablet detail pane.
  List<LogInfo> _latestEntries = const [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_listenToScroll);
    _focus.addListener(() {
      if (_focus.hasFocus && !_searching) _startSearching();
    });
  }

  @override
  void dispose() {
    _countDelay?.cancel();
    _search.dispose();
    _focus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ActivityQuery get _query => ref.read(activityLogProvider).filter;

  void _ask(ActivityQuery query) {
    ref.read(activityLogProvider.notifier).setFilter(query);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _startSearching() {
    setState(() => _searching = true);
    _scheduleCounts();
  }

  void _stopSearching() {
    _search.clear();
    _focus.unfocus();
    setState(() {
      _searching = false;
      _typed = "";
    });
  }

  void _pick(ActivityQuery query) {
    _stopSearching();
    _ask(query);
  }

  void _searchText(String text) {
    if (text.trim().isEmpty) return;
    _pick(_query.copyWith(text: text.trim()));
  }

  void _onTyped(String text) {
    setState(() => _typed = text);
    _scheduleCounts();
  }

  Future<void> _openFilter() async {
    final next = await showActivityFilterSheet(context, _query);
    if (next != null && mounted) _ask(next);
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

  Widget _kindIcon(ActivityKind kind) =>
      CornerBadge(icon: kind.icon, fill: kind.badge, size: 36, iconSize: 18);

  Widget _initialIcon(String text) {
    final palette = YiviPalette.of(context);
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: palette.tint, shape: BoxShape.circle),
      child: Text(
        text.isEmpty ? "?" : text.characters.first.toUpperCase(),
        style: palette.display(15).copyWith(color: palette.link),
      ),
    );
  }

  /// The suggestions, by group. With nothing typed: what happened and the
  /// recent parties. Typed: what happened, cards, parties and fields whose
  /// name has the typed text.
  List<(String, List<_Suggestion>)> _suggestions() {
    final q = _query;
    final typed = normaliseForSearch(_typed.trim());
    bool hit(String s) =>
        typed.isEmpty || normaliseForSearch(s).contains(typed);
    final parties = ref.watch(activityPartiesProvider).value ?? const [];
    String partySub(PartySummary p) => FlutterI18n.translate(
      context,
      "activity.query.suggest.last",
      translationParams: {
        "times": activityTimes(context, p.count),
        "date": DateFormat.MMMd(
          FlutterI18n.currentLocale(context).toString(),
        ).format(p.lastTime.toLocal()),
      },
    );

    final kinds = [
      for (final kind in activityKindOrder)
        if (hit(FlutterI18n.translate(context, kind.labelKey)))
          _Suggestion(
            key: "kind:${kind.name}",
            leading: _kindIcon(kind),
            title: FlutterI18n.translate(context, kind.labelKey),
            subtitle: "",
            query: q.copyWith(kinds: {logTypeOf(kind)}),
          ),
    ];
    if (typed.isEmpty) {
      return [
        (FlutterI18n.translate(context, "activity.query.suggest.kinds"), kinds),
        (
          FlutterI18n.translate(context, "activity.query.suggest.recent"),
          [
            for (final p in parties.take(4))
              _Suggestion(
                key: "party:${p.key}",
                leading: ActivityPartyLogo(
                  party: ActivityParty.of(p.party),
                  size: 36,
                ),
                title: p.party.name,
                subtitle: partySub(p),
                query: q.copyWith(party: () => p),
              ),
          ],
        ),
      ];
    }

    final cards = [
      for (final c in _cards)
        if (hit(c.name))
          _Suggestion(
            key: "card:${c.key}",
            leading: CredentialCardArt(
              credential: c.art,
              width: 46,
              greyedOut: c.removed,
            ),
            title: c.name,
            subtitle: c.removed
                ? FlutterI18n.translate(context, "activity.query.sheet.removed")
                : "",
            query: q.withCard(c),
          ),
    ];
    final partyHits = [
      for (final p in parties)
        if (hit(p.party.name))
          _Suggestion(
            key: "party:${p.key}",
            leading: ActivityPartyLogo(
              party: ActivityParty.of(p.party),
              size: 36,
            ),
            title: p.party.name,
            subtitle: partySub(p),
            query: q.copyWith(party: () => p),
          ),
    ];
    // A field of the card already asked about joins the fields picked; one
    // of another card replaces them: the question is about one card.
    final fields = <_Suggestion>[];
    for (final c in _cards.where((c) => !c.removed)) {
      for (final g in claimTokenGroups(c.art.attributes)) {
        for (final t in g.tokens) {
          final label = claimTokenLabel(context, t);
          if (!hit(label)) continue;
          final next = q.card == c
              ? q.copyWith(fields: {...q.fields, t}.toList())
              : q.withCard(c).copyWith(fields: [t]);
          fields.add(
            _Suggestion(
              key: "field:${c.key}:${t.key}",
              leading: _initialIcon(label),
              title: label,
              subtitle: FlutterI18n.translate(
                context,
                "activity.query.suggest.from_card",
                translationParams: {"card": c.name},
              ),
              query: next,
            ),
          );
        }
      }
    }
    return [
      if (kinds.isNotEmpty)
        (FlutterI18n.translate(context, "activity.query.suggest.kinds"), kinds),
      if (cards.isNotEmpty)
        (FlutterI18n.translate(context, "activity.query.suggest.cards"), cards),
      if (partyHits.isNotEmpty)
        (
          FlutterI18n.translate(context, "activity.query.suggest.parties"),
          partyHits,
        ),
      if (fields.isNotEmpty)
        (
          FlutterI18n.translate(context, "activity.query.suggest.fields"),
          fields,
        ),
    ];
  }

  /// Counts what each suggestion would leave, a moment after typing stops.
  void _scheduleCounts() {
    _countDelay?.cancel();
    _countDelay = Timer(const Duration(milliseconds: 150), () async {
      if (!mounted || !_searching) return;
      final generation = ++_countGeneration;
      final all = [for (final (_, items) in _suggestions()) ...items];
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

  Widget _suggestionList(double top) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final groups = _suggestions();
    final typed = _typed.trim();
    Widget row(_Suggestion s) {
      final faded = (_counts[s.key] ?? 1) == 0;
      final subtitle = faded
          ? FlutterI18n.translate(context, "activity.query.not_fitting")
          : s.subtitle;
      return Opacity(
        opacity: faded ? 0.38 : 1,
        child: Semantics(
          button: true,
          enabled: !faded,
          child: InkWell(
            key: Key("activity_suggestion_${s.key}"),
            onTap: faded ? null : () => _pick(s.query),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                child: Row(
                  spacing: 12,
                  children: [
                    SizedBox(width: 46, child: Center(child: s.leading)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: palette
                                .display(15)
                                .copyWith(color: palette.text),
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: palette
                                  .body(13)
                                  .copyWith(color: palette.secondaryText),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ListView(
      key: const Key("activity_suggestions"),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        16,
        top,
        16,
        padding.bottom + bottomBarSpace(context),
      ),
      children: [
        for (final (title, items) in groups)
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassGroup(
                header: title,
                dividerIndent: 14 + 46 + 12,
                children: [for (final s in items) row(s)],
              ),
            ),
        if (typed.isNotEmpty)
          GlassGroup(
            dividerIndent: 14 + 46 + 12,
            children: [
              row(
                _Suggestion(
                  key: "text",
                  leading: Icon(Icons.search, color: palette.link),
                  title: FlutterI18n.translate(
                    context,
                    "activity.query.suggest.search_for",
                    translationParams: {"text": typed},
                  ),
                  subtitle: FlutterI18n.translate(
                    context,
                    "activity.query.suggest.search_where",
                  ),
                  query: _query.copyWith(text: typed),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // -------------------------------------------------------------------- chips

  /// What is asked, one chip per filter, each with a cross to take it off.
  List<Widget> _chips(ActivityQuery q) {
    final card = q.card;
    return [
      if (q.kinds.isNotEmpty)
        ActivityFacetChip(
          key: const Key("activity_chip_kinds"),
          label: activityKindsLabel(context, q.kinds),
          onRemove: () => _ask(q.copyWith(kinds: {})),
        ),
      if (card != null)
        ActivityFacetChip(
          key: const Key("activity_chip_card"),
          leading: CredentialCardArt(
            credential: card.art,
            width: 26,
            greyedOut: card.removed,
          ),
          label: q.fields.isEmpty
              ? card.name
              : "${activityFieldsLabel(context, q.fields)} · ${card.name}",
          onRemove: () => _ask(q.withCard(null)),
        ),
      if (q.party != null)
        ActivityFacetChip(
          key: const Key("activity_chip_party"),
          label: q.party!.party.name,
          onRemove: () => _ask(q.copyWith(party: () => null)),
        ),
      if (q.period != ActivityPeriod.all)
        ActivityFacetChip(
          key: const Key("activity_chip_period"),
          label: activityPeriodLabel(context, q),
          onRemove: () => _ask(
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
          onRemove: () => _ask(q.copyWith(text: "")),
        ),
    ];
  }

  // --------------------------------------------------------------------- list

  Widget _buildLogEntries(
    BuildContext context,
    ActivityLogState state,
    double top,
  ) {
    final logEntries = state.entries;
    final moreLogsAvailable = state.moreAvailable;
    final query = state.filter;
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

    final clear = TextButton(
      key: const Key("activity_clear_filters"),
      onPressed: () => _ask(ActivityQuery.empty),
      child: Text(FlutterI18n.translate(context, "activity.query.clear")),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        16,
        top,
        16,
        padding.bottom + bottomBarSpace(context),
      ),
      children: [
        if (!query.isEmpty && logEntries.isNotEmpty)
          PushAway(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      activityResults(
                        context,
                        state.counts?.total ?? logEntries.length,
                      ),
                      key: const Key("activity_result_count"),
                      style: palette.body(14).copyWith(color: palette.heading),
                    ),
                  ),
                  clear,
                ],
              ),
            ),
          ),
        if (logEntries.isEmpty && !query.isEmpty) ...[
          const EmptyListMessage("activity.query.none"),
          Center(child: clear),
        ] else if (logEntries.isEmpty)
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
                      group.first.time.toLocal().year == DateTime.now().year
                          ? "MMMM"
                          : "MMMM y",
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
                  key: ValueKey(logKey(entry)),
                  logEntry: entry,
                  focusCard: query.card,
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
    final query = state.filter;
    final chips = _searching ? const <Widget>[] : _chips(query);
    // The field, and the chips under it while something is asked.
    final headerHeight = 60.0 + (chips.isEmpty ? 0 : activityChipHeight + 8);

    final filterButton = Stack(
      clipBehavior: Clip.none,
      children: [
        GlassIconButton(
          key: const Key("activity_filter_button"),
          size: 48,
          semanticsLabel: query.isEmpty
              ? FlutterI18n.translate(context, "activity.query.filter")
              : FlutterI18n.translate(
                  context,
                  "activity.query.filter_active",
                  translationParams: {"count": "${query.facetCount}"},
                ),
          onTap: _openFilter,
          icon: Icon(Icons.tune_rounded, color: palette.text),
        ),
        if (!query.isEmpty)
          Positioned(
            top: -2,
            right: -2,
            child: ExcludeSemantics(
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: palette.link,
                  shape: StadiumBorder(
                    side: BorderSide(color: palette.surface, width: 2),
                  ),
                ),
                child: Text(
                  "${query.facetCount}",
                  style: palette
                      .body(11.5)
                      .copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.onLink,
                      ),
                ),
              ),
            ),
          ),
      ],
    );

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
              ),
            ),
            if (_searching)
              TextButton(
                key: const Key("activity_search_cancel"),
                onPressed: _stopSearching,
                child: Text(
                  FlutterI18n.translate(context, "activity.query.cancel"),
                ),
              )
            else
              filterButton,
          ],
        ),
        if (chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: activityChipHeight,
              child: ListView.separated(
                key: const Key("activity_chips"),
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: chips.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => chips[i],
              ),
            ),
          ),
      ],
    );

    final listTop = top + headerHeight;
    final list = SearchScrollEdge(
      height: listTop - 4,
      top: top,
      row: row,
      child: _searching
          ? _suggestionList(listTop)
          : !state.loaded
          ? Center(child: LoadingIndicator())
          : _buildLogEntries(context, state, listTop),
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
          : ActivityDetailPane(key: ValueKey(logKey(entry)), logEntry: entry),
    );
  }
}
