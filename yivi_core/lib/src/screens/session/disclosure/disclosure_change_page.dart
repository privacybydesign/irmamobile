import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/session_state.dart";
import "../../../providers/last_shared_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../providers/wallet_cards_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/after_frame.dart";
import "../../../util/i18n.dart";
import "../../../util/text_fit.dart";
import "../../../widgets/bars/action_bar.dart";
import "../../../widgets/bars/app_bar.dart";
import "../../../widgets/bars/compact_bar.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/credential_type_thumbnail.dart";
import "../../../widgets/flight/flight.dart";
import "../../../widgets/layout/fill_scroll_view.dart";
import "../../../widgets/text/caps_label.dart";
import "../layout/session_layout.dart";
import "../layout/session_scaffold.dart";
import "../models/disclosure_plan_view.dart";
import "card_spots.dart";
import "disclosure_keys.dart";
import "disclosure_value_list.dart";
import "disclosure_words.dart";

/// What the change page asks of the flow: the sheets it opens and adding.
class ChangeActions {
  /// "Welk kaartje deel je?" for small choice [choice].
  final void Function(int choice) pickCard;

  /// "Welk kaartje deel je?" for [slot] of the option in use of [choice].
  final void Function(int choice, DisclosureSlot slot) pickSlot;

  /// "Welke combinatie deel je?" for [choice].
  final void Function(int choice) pickCombination;

  /// Adds for [choice]: [way] when there is one, else the picker.
  final void Function(int choice, AddWay? way) add;

  const ChangeActions({
    required this.pickCard,
    required this.pickSlot,
    required this.pickCombination,
    required this.add,
  });
}

/// "Kies wat je deelt" (2.3, 2.4): per choice one white card with what is
/// shared now, card by card, and the links that open the sheets. It never
/// holds a choice itself. "Klaar" (and back) returns to the overview.
class DisclosureChangePage extends ConsumerStatefulWidget {
  final SessionState session;
  final ChangeActions actions;
  final VoidCallback onDone;

  /// The optional choice to bring into view when the page opens (the hint
  /// on the overview).
  final int? scrollTo;

  /// Where each card is drawn: the heads' pictures are these places.
  final CardSpots spots;

  const DisclosureChangePage({
    super.key,
    required this.session,
    required this.actions,
    required this.onDone,
    required this.spots,
    this.scrollTo,
  });

  @override
  ConsumerState<DisclosureChangePage> createState() =>
      _DisclosureChangePageState();
}

class _DisclosureChangePageState extends ConsumerState<DisclosureChangePage> {
  final _titleKey = GlobalKey(debugLabel: "change_title");
  final _titleUnder = ValueNotifier(false);
  final _cardKeys = <int, GlobalKey>{};

  GlobalKey _cardKey(int i) =>
      _cardKeys[i] ??= GlobalKey(debugLabel: "change_card_$i");

  @override
  void initState() {
    super.initState();
    final to = widget.scrollTo;
    if (to != null) {
      afterFrame(() {
        final spot = _cardKeys[to]?.currentContext;
        if (spot != null) Scrollable.ensureVisible(spot, alignment: 0.3);
      });
    }
  }

  @override
  void dispose() {
    _titleUnder.dispose();
    super.dispose();
  }

  void _checkTitle() {
    if (!mounted) return;
    _titleUnder.value = headerUnderBar(context, _titleKey) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final t = context.tr;
    final session = widget.session;
    final id = session.id;
    final plan = session.disclosurePlan ?? DisclosurePlan(choices: const []);
    final selection = ref.watch(disclosureSelectionProvider(id));
    final sharesOf = ref.watch(sharesOfProvider(id));
    final chosen = resolve(plan, selection, sharesOf: sharesOf);
    final cards = {
      for (final c in changeCards(plan, selection, sharesOf: sharesOf))
        c.choice: c,
    };
    final optional = {
      for (final o in optionalItems(plan, selection, sharesOf: sharesOf))
        o.choice: o,
    };
    final signing = session.type == SessionType.signature;
    final title = t(signing ? "share.change.title_sign" : "share.change.title");
    final requestor = session.requestor.name;
    final notifier = ref.read(disclosureSelectionProvider(id).notifier);

    final items = <Widget>[];
    final drawn = <String>{};
    String? heading;
    for (final (i, choice) in plan.choices.indexed) {
      final card = cards[i];
      final item = optional[i];
      if (card == null && item == null) continue;
      final head = choice.optional
          ? t("share.optional.heading")
          : t(
              signing
                  ? "share.section.with_signature"
                  : "share.section.you_share",
            );
      if (head != heading) {
        items
          ..add(const SizedBox(height: 22))
          ..add(
            CapsLabel(head, padding: const EdgeInsets.fromLTRB(4, 0, 4, 8)),
          );
        heading = head;
      } else {
        items.add(const SizedBox(height: 8));
      }
      if (card != null) {
        items.add(
          _ChoiceCard(
            key: _cardKey(i),
            cardKey: choice.optional
                ? Key("change_optional_$i")
                : Key("change_card_$i"),
            change: card,
            chosen: chosen,
            spots: widget.spots,
            drawn: drawn,
            requestor: requestor,
            actions: widget.actions,
            onStop: choice.optional ? () => notifier.share(i, on: false) : null,
          ),
        );
      } else {
        items.add(
          _OptionalCard(
            key: _cardKey(i),
            item: item!,
            plan: plan,
            onLink: switch (item.link) {
              OptionalLink.chooseCombination =>
                () => widget.actions.pickCombination(i),
              OptionalLink.chooseCard => () => widget.actions.pickCard(i),
              OptionalLink.alsoShare => () => notifier.share(i, on: true),
              OptionalLink.addOne => () => widget.actions.add(
                i,
                addWays(choice).single,
              ),
              OptionalLink.add => () => widget.actions.add(i, null),
              null => null,
            },
          ),
        );
      }
    }

    final done = KeyedSubtree(
      key: const Key("change_done"),
      child: PrimaryPillButton(
        label: t("share.change.done"),
        onPressed: widget.onDone,
      ),
    );
    final titleBlock = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          title,
          key: _titleKey,
          style: palette
              .display(24, weight: FontWeight.w700)
              .copyWith(height: 30 / 24, color: palette.heading),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
        child: Text(
          t(signing ? "share.change.lead_sign" : "share.change.lead"),
          style: palette
              .body(15)
              .copyWith(height: 21 / 15, color: palette.text),
        ),
      ),
    ];
    final split = SessionLayout.of(context).split;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onDone();
      },
      // Held sideways, and on a tablet: the title and "Klaar" in the panel
      // at the left; the cards at the right (5.6).
      child: split
          ? SessionScaffold(
              wide: true,
              scrollsUnderBars: true,
              cornerClose: true,
              body: SidewaysLayout(
                panel: SessionPanel(
                  key: DisclosureKeys.panel,
                  top: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: titleBlock,
                  ),
                  action: done,
                ),
                content: SessionPanelContent(
                  key: const Key("change_page"),
                  children: items.skipWhile((w) => w is SizedBox).toList(),
                ),
              ),
            )
          : SessionScaffold(
              appBarTitle: signing
                  ? "share.change.title_sign"
                  : "share.change.title",
              barTitleVisibility: _titleUnder,
              scrollsUnderBars: true,
              bottomNavigationBar: ActionBar(actions: [done]),
              body: Builder(
                builder: (context) {
                  final insets = BarInsets.of(context);
                  return NotificationListener<ScrollNotification>(
                    onNotification: (_) {
                      _checkTitle();
                      return false;
                    },
                    child: FillScrollView(
                      key: const Key("change_page"),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16 + insets.left,
                        16 + insets.top,
                        16 + insets.right,
                        16 + insets.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [...titleBlock, ...items],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/// The white card of a shared choice: per slot its head and the values of
/// its card(s), the slot links of a big choice, the choice's link, and for
/// shared optional data "Niet delen".
class _ChoiceCard extends ConsumerWidget {
  final Key cardKey;
  final ChangeCard change;
  final Chosen chosen;
  final CardSpots spots;
  final Set<String> drawn;
  final String requestor;
  final ChangeActions actions;
  final VoidCallback? onStop;

  const _ChoiceCard({
    super.key,
    required this.cardKey,
    required this.change,
    required this.chosen,
    required this.spots,
    required this.drawn,
    required this.requestor,
    required this.actions,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final t = context.tr;
    final wallet = ref.watch(walletCardsProvider);
    final i = change.choice;
    String kindLink(DisclosureSlot slot) => t("share.change.pick_kind", {
      "another": anotherOf(context, slotName(slot)),
      "name": slotName(slot),
    });

    final children = <Widget>[];
    for (final (n, slot) in change.slots.indexed) {
      final shown = chosen.of(slot);
      children.add(
        Container(
          key: Key("change_slot_${i}_${slot.id}"),
          margin: EdgeInsets.only(left: n == 0 ? 0 : 16),
          decoration: n == 0
              ? null
              : BoxDecoration(
                  border: Border(top: BorderSide(color: palette.divider)),
                ),
          padding: EdgeInsets.fromLTRB(n == 0 ? 16 : 0, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (k, card) in shown.indexed) ...[
                if (k > 0) const SizedBox(height: 12),
                SharedCardBlock(
                  card: card,
                  children: [
                    CardHead(
                      art: FlightSpot.maybe(
                        spots.firstOf("change", card.hash, drawn),
                        CredentialCardArt(
                          credential: sharedCardFor(card, wallet),
                          width: 40,
                        ),
                      ),
                      name: card.name,
                      issuer: card.issuer.name,
                    ),
                    const SizedBox(height: 6),
                    DisclosureValueList(
                      card: card,
                      requestor: requestor,
                      foldable: true,
                    ),
                  ],
                ),
              ],
              if (change.slotLinks[slot.id] case final link?)
                ChangeLinkRow(
                  key: Key("change_pick_slot_${i}_${slot.id}"),
                  label: link == ChangeLink.pickSeveral
                      ? t("share.change.pick_several")
                      : kindLink(slot),
                  shortLabel: link == ChangeLink.pickSeveral
                      ? null
                      : t("share.change.pick_card"),
                  onTap: () => actions.pickSlot(i, slot),
                ),
            ],
          ),
        ),
      );
    }
    final link = change.link;
    if (link != null) {
      final row = ChangeLinkRow(
        key: link == ChangeLink.pickCombination
            ? Key("change_combination_$i")
            : Key("change_pick_$i"),
        label: switch (link) {
          ChangeLink.pickCard => t("share.change.pick_card"),
          ChangeLink.pickKind => kindLink(change.slots.single),
          ChangeLink.pickSeveral => t("share.change.pick_several"),
          ChangeLink.pickCombination => t("share.change.pick_combination"),
        },
        shortLabel: link == ChangeLink.pickKind
            ? t("share.change.pick_card")
            : null,
        onTap: () => switch (link) {
          ChangeLink.pickCombination => actions.pickCombination(i),
          ChangeLink.pickSeveral => actions.pickSlot(i, change.slots.single),
          _ => actions.pickCard(i),
        },
      );
      children.add(
        link == ChangeLink.pickCombination
            ? DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: palette.divider)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: row,
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: row,
              ),
      );
    }
    if (onStop case final stop?) {
      children.add(
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: palette.divider)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ChangeLinkRow(
              key: Key("change_optional_off_$i"),
              label: t("share.optional.stop"),
              disc: Icons.remove_rounded,
              onTap: stop,
            ),
          ),
        ),
      );
    }
    return _WhiteCard(
      key: cardKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [...children, const SizedBox(height: 4)],
      ),
    );
  }
}

/// An optional choice that is not shared: the card(s) it is about, what it
/// is, and the one link named after what the tap does.
class _OptionalCard extends ConsumerWidget {
  final OptionalItem item;
  final DisclosurePlan plan;
  final VoidCallback? onLink;

  const _OptionalCard({
    super.key,
    required this.item,
    required this.plan,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tr;
    final wallet = ref.watch(walletCardsProvider);
    final choice = plan.choices[item.choice];
    final option = choice.options[item.shownOption];
    final owned = option.slots.every((s) => s.candidates.any(usable));
    final arts = [
      for (final s in option.slots.take(3))
        if (s.candidates.firstWhereOrNull(usable) case final c?)
          CredentialCardArt(credential: sharedCardFor(c, wallet), width: 40)
        else if (addableFor(s) case final d?)
          Opacity(
            opacity: 0.45,
            child: CredentialTypeThumbnail(descriptor: d, width: 40),
          ),
    ];
    final several = choice.options.length > 1;
    final name = several
        ? capitalised(
            t("share.optional.ways", {
              "count": countWord(context, choice.options.length),
            }),
          )
        : [for (final s in option.slots) slotName(s)].join(" + ");
    final sub = !owned
        ? t("share.overview.not_in_app")
        : several
        ? [
            for (final o in choice.options)
              [for (final s in o.slots) slotName(s)].join(" + "),
          ].join(" · ")
        : slotIssuer(option.slots.first)?.name ?? "";
    final link = item.link;
    return _WhiteCard(
      key: Key("change_optional_${item.choice}"),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardHead(
              art: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: arts,
              ),
              name: name,
              issuer: sub,
            ),
            if (link != null)
              ChangeLinkRow(
                key: Key("change_optional_link_${item.choice}"),
                label: switch (link) {
                  OptionalLink.chooseCombination => t(
                    "share.optional.choose_combination",
                  ),
                  OptionalLink.chooseCard => t("share.optional.choose_card"),
                  OptionalLink.alsoShare => t("share.optional.also_share"),
                  OptionalLink.addOne => t("share.optional.add", {
                    "name":
                        addableFor(addWays(choice).single.todo.first)?.name ??
                        "",
                  }),
                  OptionalLink.add => t("share.optional.add_card"),
                },
                shortLabel: link == OptionalLink.addOne
                    ? t("share.optional.add_card")
                    : null,
                disc: switch (link) {
                  OptionalLink.addOne || OptionalLink.add => Icons.add_rounded,
                  _ => null,
                },
                chevron:
                    link == OptionalLink.chooseCombination ||
                    link == OptionalLink.chooseCard,
                onTap: onLink,
              ),
          ],
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: YiviPalette.of(context).surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );
}

/// One card that is shared, on the change page: its head and its values.
class SharedCardBlock extends StatelessWidget {
  final SelectableCredentialInstance card;
  final List<Widget> children;

  const SharedCardBlock({
    super.key,
    required this.card,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );
}

/// A card's head on the change page and in the sheets: its picture (40
/// wide), its type name in bold and the issuer under it.
class CardHead extends StatelessWidget {
  final Widget art;
  final String name;
  final String issuer;
  final bool muted;

  const CardHead({
    super.key,
    required this.art,
    required this.name,
    required this.issuer,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Row(
      spacing: YiviSpace.x12,
      children: [
        Opacity(opacity: muted ? 0.6 : 1, child: art),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: palette
                    .display(15, weight: FontWeight.w600)
                    .copyWith(
                      height: 20 / 15,
                      color: muted ? palette.secondaryText : palette.text,
                    ),
              ),
              if (issuer.isNotEmpty)
                Text(
                  issuer,
                  style: palette
                      .body(13)
                      .copyWith(height: 18 / 13, color: palette.secondaryText),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A link on the change page and in the sheets: plain blue text, left
/// aligned, 44 high; a chevron when it takes you somewhere, a plus or minus
/// disc in front when it adds or stops sharing (2.3, chevron rule).
class ChangeLinkRow extends StatelessWidget {
  final String label;
  final IconData? disc;
  final bool chevron;
  final VoidCallback? onTap;

  /// Shown instead of [label] when that does not fit on one line (a link
  /// that names a card falls back to a generic one). Screen readers still
  /// hear [label].
  final String? shortLabel;

  const ChangeLinkRow({
    super.key,
    required this.label,
    this.disc,
    bool? chevron,
    required this.onTap,
    this.shortLabel,
  }) : chevron = chevron ?? disc == null;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final style = palette
        .body(15, weight: FontWeight.w600)
        .copyWith(color: palette.link);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            spacing: 8,
            children: [
              if (disc case final icon?)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: palette.infoSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: palette.link),
                ),
              Flexible(
                child: shortLabel == null
                    ? Text(label, style: style)
                    : LayoutBuilder(
                        builder: (context, constraints) => Text(
                          labelThatFits(
                            context,
                            full: label,
                            short: shortLabel,
                            style: style,
                            width: constraints.maxWidth,
                          ),
                          style: style,
                        ),
                      ),
              ),
              if (chevron)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: palette.link,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
