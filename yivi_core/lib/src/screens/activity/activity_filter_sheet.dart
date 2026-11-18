import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/activity_query.dart";
import "../../providers/activity_providers.dart";
import "../../providers/credentials_search.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/after_frame.dart";
import "../../util/i18n.dart";
import "../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../widgets/glass/glass_group.dart";
import "../../widgets/glass/glass_search_field.dart";
import "../../widgets/glass/glass_sheet.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/glass/sheet_actions.dart";
import "../../widgets/list_row.dart";
import "../../widgets/section_header.dart";
import "../../widgets/yivi_spinner.dart";
import "activity_entry.dart";
import "activity_options.dart";
import "activity_query_labels.dart";
import "widgets/activity_detail_parts.dart";
import "widgets/activity_query_chips.dart";

/// Builds a question to the activity log, starting from [query]: what
/// happened, the card and which of its fields, with whom and when. A
/// sentence at the top says what is asked; the button shows how many
/// entries match. Options that would leave nothing with the rest are faded.
/// Returns the new question, or null when the sheet is closed.
Future<ActivityQuery?> showActivityFilterSheet(
  BuildContext context,
  ActivityQuery query,
) => showGlassSheet<ActivityQuery>(
  context: context,
  builder: (_) => _ActivityFilterSheet(initial: query),
);

class _ActivityFilterSheet extends ConsumerStatefulWidget {
  final ActivityQuery initial;

  const _ActivityFilterSheet({required this.initial});

  @override
  ConsumerState<_ActivityFilterSheet> createState() =>
      _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends ConsumerState<_ActivityFilterSheet> {
  late ActivityQuery _q = widget.initial;
  bool _allParties = false;

  /// The cards to pick from are on a page of their own: a wallet can have
  /// many.
  bool _pickingCard = false;

  /// What is typed in the card page's search.
  String _cardSearch = "";

  /// Whether the sheet is all the way up. Until then, and until the lists
  /// the options come from are in, it shows a spinner: drawing every option
  /// (card pictures) while it slides up held it back.
  bool _opened = false;
  Animation<double>? _opening;

  /// How many entries match the question, and each option tried in it.
  int? _total;
  final _counts = <String, int>{};
  late final _counter = ActivityOptionCounter(
    ref.read(activityLogClientProvider),
  );

  @override
  void initState() {
    super.initState();
    afterFrame(_recount);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final opening = ModalRoute.of(context)?.animation;
    if (opening == _opening) return;
    _opening?.removeStatusListener(_onOpening);
    _opening = opening;
    if (opening == null || opening.isCompleted) {
      _opened = true;
    } else {
      opening.addStatusListener(_onOpening);
    }
  }

  void _onOpening(AnimationStatus status) {
    if (status != AnimationStatus.completed || _opened) return;
    _opening?.removeStatusListener(_onOpening);
    if (mounted) setState(() => _opened = true);
  }

  @override
  void dispose() {
    _opening?.removeStatusListener(_onOpening);
    super.dispose();
  }

  void _set(ActivityQuery q) {
    setState(() => _q = q);
    _recount();
  }

  /// Counts the question and every option in it with one question to
  /// irmago: an option that leaves nothing gets faded. A count irmago left
  /// out counts as nothing.
  Future<void> _recount() async {
    if (!mounted) return;
    final options = activityFilterOptions(
      _q,
      cards: _cards,
      parties: ref.read(activityPartiesProvider).value ?? const [],
    );
    final tries = <String, ActivityQuery>{
      "total": _q,
      for (final o in options) o.key: o.query,
    };
    final counts = await _counter.count(tries);
    if (counts == null || !mounted) return;
    setState(() {
      _counts.clear();
      for (final k in tries.keys) {
        _counts[k] = counts[k] ?? 0;
      }
      _total = _q.rangeWrong ? 0 : _counts["total"];
    });
  }

  List<ActivityCardRef> get _cards => ref.read(activityCardRefsProvider);

  /// Whether the option can still be picked. Unknown counts never fade.
  bool _fits(String key) => (_counts[key] ?? 1) > 0;

  String _t(String key, [Map<String, String>? params]) =>
      context.tr("activity.query.$key", params);

  @override
  Widget build(BuildContext context) {
    // Recount once the lists the options come from are in.
    ref.listen(activityPartiesProvider, (_, _) => _recount());
    ref.listen(removedCardTypesProvider, (_, _) => _recount());

    final palette = YiviPalette.of(context);
    final total = _total;
    final ready =
        _opened &&
        ref.watch(activityPartiesProvider).hasValue &&
        ref.watch(removedCardTypesProvider).hasValue;
    return GlassSheetPages(
      // The swipe and the system back, as the card page's back button.
      onBack: () => setState(_leaveCardPage),
      pages: [
        _main(palette, total, ready),
        if (_pickingCard) _cardPage(palette),
      ],
    );
  }

  void _leaveCardPage() {
    _pickingCard = false;
    _cardSearch = "";
  }

  Widget _main(YiviPalette palette, int? total, bool ready) {
    return GlassSheetPage.scroll(
      key: const Key("activity_filter_main"),
      title: SheetTitle(_t("sheet.title")),
      padding: const EdgeInsets.fromLTRB(
        YiviSpace.x16,
        YiviSpace.x4,
        YiviSpace.x16,
        YiviSpace.x24,
      ),
      action: SheetAction(
        key: const Key("activity_filter_apply"),
        label: total == null
            ? _t("sheet.title")
            : total == 0
            ? _t("sheet.no_results")
            : context.plural("activity.query.sheet.show", total),
        onTap: total == null || total > 0
            ? () => Navigator.of(context).pop(_q)
            : null,
      ),
      child: !ready
          ? SizedBox(
              key: const Key("activity_filter_loading"),
              height: 240,
              child: Center(child: YiviSpinner()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _readback(palette),
                _heading(_t("sheet.kinds"), _t("sheet.many")),
                _kinds(),
                _heading(_t("sheet.card"), _t("sheet.one")),
                _cardRow(palette),
                if (_q.card != null) ..._fields(palette),
                _heading(_t("sheet.party"), _t("sheet.one")),
                _partyList(palette),
                _heading(_t("sheet.when"), null),
                _periods(palette),
              ],
            ),
    );
  }

  Widget _readback(YiviPalette palette) => Container(
    padding: const EdgeInsets.fromLTRB(
      YiviSpace.x16,
      YiviSpace.x12,
      YiviSpace.x8,
      YiviSpace.x12,
    ),
    decoration: BoxDecoration(
      color: palette.tint,
      borderRadius: YiviCorners.cardRadius,
    ),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              activityQuerySentence(context, _q, _total),
              key: const Key("activity_filter_readback"),
              style: palette.body(15).copyWith(color: palette.text),
            ),
          ),
        ),
        if (!_q.isEmpty)
          TextLink(
            key: const Key("activity_filter_clear"),
            label: _t("sheet.clear"),
            onPressed: () => _set(ActivityQuery.empty),
          ),
      ],
    ),
  );

  Widget _heading(String title, String? hint) =>
      SectionHeader(title, hint: hint);

  Widget _kinds() => Wrap(
    spacing: YiviSpace.x8,
    runSpacing: YiviSpace.x8,
    children: [
      for (final kind in ActivityKind.ordered)
        Builder(
          builder: (context) {
            final type = kind.logType;
            final on = _q.kinds.contains(type);
            final faded = !on && !_fits("kind:${kind.name}");
            return ActivityToggleTag(
              key: Key("activity_filter_kind_${kind.name}"),
              label: context.tr(kind.labelKey),
              kind: kind,
              selected: on,
              faded: faded,
              onTap: () => _set(
                _q.copyWith(
                  kinds: on
                      ? ({..._q.kinds}..remove(type))
                      : {..._q.kinds, type},
                ),
              ),
            );
          },
        ),
    ],
  );

  /// One row of a list in the sheet: something to pick, with a check when
  /// it is picked, and faded when it would leave nothing.
  Widget _pickRow({
    required Key key,
    required Widget leading,
    required String title,
    required String subtitle,
    required bool selected,
    required bool faded,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final palette = YiviPalette.of(context);
    return ListRow(
      key: key,
      leading: leading,
      title: title,
      titleMaxLines: 1,
      subtitle: subtitle.isEmpty ? null : subtitle,
      dense: true,
      // The check's room is kept, so the rows line up.
      trailingWidget: SizedBox(
        width: 22,
        child:
            trailing ??
            (selected
                ? Icon(Icons.check_rounded, size: 22, color: palette.link)
                : null),
      ),
      selected: selected,
      // Fits none of the other choices: greyed out, no taps.
      enabled: !faded,
      onTap: onTap,
    );
  }

  /// "3 passen bij je keuzes" when [others] (the rest of the question) asks
  /// something, else how often it is in the log at all ([all], or its own
  /// count).
  String _fitText(String key, {required bool others, int? all}) {
    final n = _counts[key];
    if (others) {
      if (n == null) return "";
      return n == 0
          ? _t("sheet.not_fitting")
          : context.plural("activity.query.sheet.fits", n);
    }
    final count = all ?? n;
    return count == null
        ? ""
        : context.plural("activity.query.sheet.in_activity", count);
  }

  /// The card asked about, or "Any card": one row that opens the cards on a
  /// page of their own.
  Widget _cardRow(YiviPalette palette) {
    final card = _q.card;
    return GlassGroup(
      dividerIndent: 14 + 46 + 12,
      children: [
        _pickRow(
          key: const Key("activity_filter_card"),
          leading: card == null
              ? _anyCard(palette)
              : CredentialCardArt(
                  credential: card.art,
                  width: 46,
                  greyedOut: card.removed,
                ),
          title: card?.name ?? _t("sheet.any_card"),
          subtitle: card == null
              ? _t("sheet.pick_card", {"count": "${_cards.length}"})
              : _fitText(
                  "card:${card.key}",
                  others: !_q.withCard(null).isEmpty,
                ),
          selected: false,
          faded: false,
          trailing: Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: palette.secondaryText,
          ),
          onTap: () => setState(() => _pickingCard = true),
        ),
      ],
    );
  }

  /// In the place of a card picture: any card.
  Widget _anyCard(YiviPalette palette) => Container(
    width: 46,
    height: 46 / CredentialCardArt.aspectRatio,
    decoration: BoxDecoration(
      color: palette.tint,
      borderRadius: CredentialCardArt.radiusFor(46),
    ),
    child: Icon(Icons.style_outlined, size: 18, color: palette.heading),
  );

  /// Every card, to pick one: the one picked has a check, "Any card" on
  /// top takes it away. Picking goes back to the filter.
  Widget _cardPage(YiviPalette palette) {
    // Searched by the card's name or who issued it; "Any card" only
    // without a search.
    final typed = normaliseForSearch(_cardSearch.trim());
    final searching = typed.isNotEmpty;
    final cards = [
      for (final c in _cards)
        if (!searching ||
            normaliseForSearch(c.name).contains(typed) ||
            normaliseForSearch(c.art.issuer.name).contains(typed))
          c,
    ];
    final any = searching ? 0 : 1;
    void pick(ActivityCardRef? c) => setState(() {
      _leaveCardPage();
      _set(_q.withCard(c));
    });
    return GlassSheetPage.scroll(
      key: const Key("activity_filter_cards"),
      title: SheetTitle(_t("sheet.card")),
      exits: SheetExits(onBack: () => setState(_leaveCardPage)),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            YiviSpace.x16,
            YiviSpace.x4,
            YiviSpace.x16,
            YiviSpace.x12,
          ),
          sliver: SliverToBoxAdapter(
            child: GlassSearchField(
              fieldKey: const Key("activity_filter_card_search"),
              hintKey: "activity.query.sheet.search_cards",
              onChanged: (text) => setState(() => _cardSearch = text),
            ),
          ),
        ),
        if (cards.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(YiviSpace.x24),
              child: Text(
                _t("sheet.no_cards"),
                key: const Key("activity_filter_card_none"),
                textAlign: TextAlign.center,
                style: palette.body(15).copyWith(color: palette.secondaryText),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              YiviSpace.x16,
              YiviSpace.x4,
              YiviSpace.x16,
              YiviSpace.x24,
            ),
            sliver: SliverGlassGroup(
              dividerIndent: 14 + 46 + 12,
              itemCount: cards.length + any,
              itemBuilder: (context, i) {
                if (i < any) {
                  return _pickRow(
                    key: const Key("activity_filter_card_any"),
                    leading: _anyCard(palette),
                    title: _t("sheet.any_card"),
                    subtitle: "",
                    selected: _q.card == null,
                    faded: false,
                    onTap: () => pick(null),
                  );
                }
                final c = cards[i - any];
                final key = "card:${c.key}";
                final on = _q.card == c;
                final fit = _fitText(key, others: !_q.withCard(null).isEmpty);
                return _pickRow(
                  key: Key("activity_filter_card_${c.key}"),
                  leading: CredentialCardArt(
                    credential: c.art,
                    width: 46,
                    greyedOut: c.removed,
                  ),
                  title: c.name,
                  subtitle: c.removed ? "${_t("sheet.removed")} · $fit" : fit,
                  selected: on,
                  faded: !on && !_fits(key),
                  onTap: () => pick(on ? null : c),
                );
              },
            ),
          ),
      ],
    );
  }

  /// The fields of the picked card: loose fields first, then each group
  /// under its heading with "Alles" first. Picking "Alles" lights up the
  /// group's fields as included; tapping one of those keeps only it.
  List<Widget> _fields(YiviPalette palette) {
    final card = _q.card!;
    final groups = claimTokenGroups(card.art.attributes);
    if (groups.isEmpty) return const [];
    return [
      _heading(_t("sheet.fields", {"card": card.name}), _t("sheet.many")),
      for (final g in groups) ...[
        if (g.title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              YiviSpace.x4,
              YiviSpace.x12,
              YiviSpace.x4,
              YiviSpace.x8,
            ),
            child: Text(
              g.title!,
              style: palette
                  .body(13)
                  .copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.secondaryText,
                  ),
            ),
          ),
        Wrap(
          spacing: YiviSpace.x8,
          runSpacing: YiviSpace.x8,
          children: [
            for (final t in g.tokens)
              Builder(
                builder: (context) {
                  final all = g.all;
                  final allOn = all != null && _q.fields.contains(all);
                  final on = _q.fields.contains(t);
                  final included = !on && allOn && !t.isGroup;
                  final faded = !on && !included && !_fits("field:${t.key}");
                  return ActivityToggleTag(
                    key: Key("activity_filter_field_${t.key}"),
                    label: g.title == null
                        ? claimTokenLabel(context, t)
                        : claimTokenShortLabel(context, t),
                    selected: on,
                    included: included,
                    faded: faded,
                    onTap: () {
                      final List<ClaimToken> next;
                      if (t.isGroup) {
                        next = on
                            ? [
                                for (final x in _q.fields)
                                  if (x != t) x,
                              ]
                            : [
                                for (final x in _q.fields)
                                  if (!g.tokens.contains(x)) x,
                                t,
                              ];
                      } else if (included) {
                        next = [
                          for (final x in _q.fields)
                            if (x != all) x,
                          t,
                        ];
                      } else {
                        next = on
                            ? [
                                for (final x in _q.fields)
                                  if (x != t) x,
                              ]
                            : [..._q.fields, t];
                      }
                      _set(_q.copyWith(fields: next));
                    },
                  );
                },
              ),
          ],
        ),
      ],
    ];
  }

  Widget _partyList(YiviPalette palette) {
    final parties = ref.watch(activityPartiesProvider).value ?? const [];
    final picked = _q.party;
    final shown = [...(_allParties ? parties : parties.take(5))];
    if (picked != null && !shown.any((p) => p.key == picked.key)) {
      shown.add(picked);
    }
    return GlassGroup(
      dividerIndent: 14 + 36 + 12,
      children: [
        for (final p in shown)
          Builder(
            builder: (context) {
              final key = "party:${p.key}";
              final on = picked?.key == p.key;
              return _pickRow(
                key: Key("activity_filter_party_${p.key}"),
                leading: ActivityPartyLogo(
                  party: ActivityParty.of(p.party),
                  size: 36,
                ),
                title: p.party.name,
                subtitle: _fitText(
                  key,
                  others: !_q.copyWith(party: () => null).isEmpty,
                  all: p.count,
                ),
                selected: on,
                faded: !on && !_fits(key),
                onTap: () => _set(_q.copyWith(party: () => on ? null : p)),
              );
            },
          ),
        if (!_allParties && parties.length > 5)
          InkWell(
            key: const Key("activity_filter_all_parties"),
            onTap: () => setState(() => _allParties = true),
            child: SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  _t("sheet.all_parties", {"count": "${parties.length}"}),
                  style: palette
                      .body(15)
                      .copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.link,
                      ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _periods(YiviPalette palette) {
    final custom = _q.period == ActivityPeriod.custom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: YiviSpace.x8,
          runSpacing: YiviSpace.x8,
          children: [
            for (final p in ActivityPeriod.values)
              Builder(
                builder: (context) {
                  final on = _q.period == p;
                  return ActivityToggleTag(
                    key: Key("activity_filter_period_${p.name}"),
                    label: context.tr(p.labelKey),
                    selected: on,
                    faded: !on && !_fits("period:${p.name}"),
                    onTap: () {
                      if (p == ActivityPeriod.custom) {
                        // The range starts as all of it: from the first
                        // entry (or a year back) up to today.
                        final today = DateTime.now();
                        _set(
                          _q.copyWith(
                            period: p,
                            from: () =>
                                _q.from ??
                                DateTime(
                                  today.year - 1,
                                  today.month,
                                  today.day,
                                ),
                            to: () =>
                                _q.to ??
                                DateTime(today.year, today.month, today.day),
                          ),
                        );
                      } else {
                        _set(
                          _q.copyWith(
                            period: p,
                            from: () => null,
                            to: () => null,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
          ],
        ),
        // The range, only for a custom period.
        if (custom) ...[
          const SizedBox(height: YiviSpace.x12),
          Row(
            spacing: YiviSpace.x8,
            children: [
              Expanded(
                child: _dateBox(
                  key: const Key("activity_filter_from"),
                  label: _t("sheet.from"),
                  value: _q.from,
                  onPicked: (d) => _set(_q.copyWith(from: () => d)),
                ),
              ),
              Expanded(
                child: _dateBox(
                  key: const Key("activity_filter_to"),
                  label: _t("sheet.to"),
                  value: _q.to,
                  onPicked: (d) => _set(_q.copyWith(to: () => d)),
                ),
              ),
            ],
          ),
          if (_q.rangeWrong)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                YiviSpace.x4,
                YiviSpace.x8,
                YiviSpace.x4,
                0,
              ),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _t("sheet.range_wrong"),
                  style: palette.body(13).copyWith(color: palette.danger),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _dateBox({
    required Key key,
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPicked,
  }) {
    final palette = YiviPalette.of(context);
    final shown = value == null
        ? _t("sheet.pick_date")
        : MaterialLocalizations.of(context).formatMediumDate(value);
    return Semantics(
      button: true,
      label: "$label, $shown",
      excludeSemantics: true,
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: YiviCorners.cardRadius,
          side: BorderSide(color: palette.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: key,
          onTap: () async {
            final today = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? today,
              firstDate: DateTime(2018),
              lastDate: today,
            );
            if (picked != null && mounted) onPicked(picked);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              YiviSpace.x12,
              YiviSpace.x8,
              YiviSpace.x12,
              YiviSpace.x12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: palette
                      .body(12)
                      .copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.secondaryText,
                      ),
                ),
                const SizedBox(height: YiviSpace.x2),
                Text(
                  shown,
                  style: palette.body(15).copyWith(color: palette.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
