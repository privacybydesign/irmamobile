import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/session_state.dart";
import "../../../providers/last_shared_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../providers/wallet_cards_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/i18n.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/flight/flight.dart";
import "../../../widgets/sheet/sheet.dart";
import "../../../widgets/sheet/sheet_actions.dart";
import "../../../widgets/sheet/sheet_heading.dart";
import "../models/disclosure_plan_view.dart";
import "card_spots.dart";
import "disclosure_change_page.dart" show CardHead, ChangeLinkRow;
import "disclosure_value_list.dart";
import "disclosure_words.dart";

/// "Welk kaartje deel je?" (2.5.1): for small choice [choice], or for [slot]
/// of the option in use of [choice] (a slot in a big choice, or one that
/// takes several cards). A tap only selects; "Kies" (or "Klaar" where
/// several can be ticked) applies it; closing discards it. [onAdd] adds
/// another card ("＋ Ander … toevoegen"), after the sheet has closed: one
/// way per kind the sheet can add, also kinds already in the app.
Future<void> showWhichCardSheet({
  required BuildContext context,
  required int sessionId,
  required int choice,
  DisclosureSlot? slot,
  required void Function(int choice, List<AddWay> ways) onAdd,
  CardSpots? spots,
  void Function(Map<String, Rect> boxes)? onLeave,
  bool carried = false,
}) => showSheet<void>(
  context: context,
  // A card carried over its edge: it comes up under the card.
  motion: carried ? SheetMotion.carried : SheetMotion.share,
  builder: (_) => WhichCardSheetView(
    key: const Key("which_card_sheet"),
    sessionId: sessionId,
    choice: choice,
    slot: slot,
    onAdd: onAdd,
    spots: spots,
    onLeave: onLeave,
  ),
);

class WhichCardSheetView extends ConsumerStatefulWidget {
  final int sessionId;
  final int choice;
  final DisclosureSlot? slot;
  final void Function(int choice, List<AddWay> ways) onAdd;

  /// Where the cards are drawn: the rows' pictures are the "sheet" places.
  final CardSpots? spots;

  /// The sheet goes: the boxes of its cards, for the flight back.
  final void Function(Map<String, Rect> boxes)? onLeave;

  const WhichCardSheetView({
    super.key,
    required this.sessionId,
    required this.choice,
    this.slot,
    required this.onAdd,
    this.spots,
    this.onLeave,
  });

  @override
  ConsumerState<WhichCardSheetView> createState() => _WhichCardSheetState();
}

/// What is picked in the sheet before "Kies": a row (by its first card's
/// hash), "Niet delen" (null), or for several the ticked rows.
class _Pick {
  final String? hash;
  final int? option;
  final Set<String> ticked;
  const _Pick({this.hash, this.option, this.ticked = const {}});
}

class _WhichCardSheetState extends ConsumerState<WhichCardSheetView> {
  _Pick? _pick;
  final _title = GlobalKey(debugLabel: "which_card_title");

  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    final palette = YiviPalette.of(context);
    final id = widget.sessionId;
    final session = ref.watch(sessionStateProvider(id)).value;
    final plan = session?.disclosurePlan;
    if (session == null ||
        plan == null ||
        widget.choice >= plan.choices.length) {
      return const SizedBox.shrink();
    }
    final selection = ref.watch(disclosureSelectionProvider(id));
    final sharesOf = ref.watch(sharesOfProvider(id));
    final wallet = ref.watch(walletCardsProvider);
    final requestor = session.requestor.name;
    final signing = session.type == SessionType.signature;
    final choice = plan.choices[widget.choice];
    // The slot of the sheet, as the plan has it now.
    final slot = widget.slot == null
        ? null
        : choice.options
              .expand((o) => o.slots)
              .firstWhereOrNull((s) => s.id == widget.slot!.id);
    final sheet = slot == null
        ? sheetRowsForChoice(widget.choice, plan, selection, sharesOf: sharesOf)
        : sheetRowsForSlot(
            widget.choice,
            slot,
            plan,
            selection,
            sharesOf: sharesOf,
          );

    // What is picked: the sheet's own pick, else what is in use.
    final inUse = sheet.rows.where((r) => r.selected).toList();
    final pick =
        _pick ??
        (sheet.multiple
            ? _Pick(ticked: {for (final r in inUse) r.group.first.hash})
            : inUse.isEmpty
            ? const _Pick()
            : _Pick(
                hash: inUse.first.group.first.hash,
                option: inUse.first.option,
              ));
    bool picked(SheetRow r) => sheet.multiple
        ? pick.ticked.contains(r.group.first.hash)
        : pick.hash == r.group.first.hash;
    final nothingPicked =
        sheet.nothingRow && pick.hash == null && !sheet.multiple;

    void apply() {
      final n = ref.read(disclosureSelectionProvider(id).notifier);
      if (sheet.multiple) {
        n.chooseCards(slot!.id, [
          for (final r in sheet.rows)
            if (pick.ticked.contains(r.group.first.hash)) r.group.first.hash,
        ]);
      } else if (pick.hash == null) {
        if (choice.optional) n.share(widget.choice, on: false);
      } else {
        final row = sheet.rows.firstWhere(
          (r) => r.group.first.hash == pick.hash,
        );
        n.chooseOption(widget.choice, row.option);
        n.chooseCards(row.slot.id, [row.group.first.hash]);
        if (choice.optional) n.share(widget.choice, on: true);
      }
      Navigator.of(context).pop();
    }

    void tap(SheetRow r) => setState(() {
      if (sheet.multiple) {
        final next = {...pick.ticked};
        if (!next.remove(r.group.first.hash)) next.add(r.group.first.hash);
        // At least one stays picked.
        if (next.isNotEmpty) _pick = _Pick(ticked: next);
      } else {
        _pick = _Pick(hash: r.group.first.hash, option: r.option);
      }
    });

    void add() {
      final ways = [
        for (final s in sheet.addable)
          AddWay(
            choice.options.indexWhere((o) => o.slots.any((x) => x.id == s.id)),
            [s],
            const [],
          ),
      ];
      Navigator.of(context).pop();
      widget.onAdd(widget.choice, ways);
    }

    final title = t(
      sheet.multiple
          ? (signing ? "share.pick.title_many_sign" : "share.pick.title_many")
          : (signing ? "share.pick.title_sign" : "share.pick.title"),
    );
    final first = sheet.rows.firstOrNull;
    final children = <Widget>[
      if (sheet.nothingRow)
        _PickRow(
          key: const Key("which_card_nothing"),
          radio: sheet.radios,
          multiple: false,
          selected: nothingPicked,
          onTap: () => setState(() => _pick = const _Pick()),
          child: Text(
            t("share.change.not_sharing"),
            style: palette
                .display(15, weight: FontWeight.w600)
                .copyWith(color: palette.text),
          ),
        ),
      if (sheet.oneKind && first != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: CardHead(
            art: FlightSpot.maybe(
              widget.spots?.of(
                "sheet",
                (inUse.firstOrNull ?? first).group.first.hash,
              ),
              CredentialCardArt(
                credential: sharedCardFor(first.group.first, wallet),
                width: 40,
              ),
            ),
            name: first.group.first.name,
            issuer: first.group.first.issuer.name,
          ),
        ),
      for (final r in sheet.rows)
        _PickRow(
          key: Key("which_card_row_${r.group.first.hash}"),
          radio: sheet.radios && r.problem == null,
          multiple: sheet.multiple,
          selected: picked(r),
          muted: r.problem != null,
          onTap: r.problem != null || !sheet.radios ? null : () => tap(r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!sheet.oneKind) ...[
                CardHead(
                  art: FlightSpot.maybe(
                    widget.spots?.of("sheet", r.group.first.hash),
                    CredentialCardArt(
                      credential: sharedCardFor(r.group.first, wallet),
                      width: 40,
                    ),
                  ),
                  name: r.group.first.name,
                  issuer: r.group.first.issuer.name,
                ),
                const SizedBox(height: 6),
              ],
              DisclosureValueList(card: r.group.first, requestor: requestor),
              if (r.group.count > 1)
                Text(
                  t("share.pick.same_values", {
                    "count": countWord(context, r.group.count),
                  }),
                  style: palette
                      .body(13)
                      .copyWith(color: palette.secondaryText),
                ),
              if (r.problem case final p?)
                Text(
                  t(
                    signing
                        ? "share.problem.cant_use"
                        : "share.problem.cant_share",
                    {"problem": problemWord(context, p)},
                  ),
                  style: palette
                      .body(13, weight: FontWeight.w600)
                      .copyWith(color: palette.errorText),
                ),
            ],
          ),
        ),
      if (sheet.addable.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: KeyedSubtree(
            // For tests: the type(s) it adds.
            key: Key(
              "sheet_add_${[for (final s in sheet.addable) slotType(s)].join("+")}",
            ),
            child: ChangeLinkRow(
              key: const Key("which_card_add"),
              label: sheet.addable.length == 1
                  ? t("share.pick.add_another", {
                      "another": anotherOf(
                        context,
                        slotName(sheet.addable.single),
                      ),
                      "name": slotName(sheet.addable.single),
                    })
                  : t("share.pick.add_card"),
              shortLabel: sheet.addable.length == 1
                  ? t("share.pick.add_card")
                  : null,
              disc: Icons.add_rounded,
              onTap: add,
            ),
          ),
        ),
    ];

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          widget.onLeave?.call(
            widget.spots?.boxes(context, "sheet") ?? const {},
          );
        }
      },
      child: SheetPage.scroll(
        title: SheetTitle(title, reveal: SheetTitleReveal.under(_title)),
        padding: const EdgeInsets.fromLTRB(
          YiviSpace.x16,
          0,
          YiviSpace.x16,
          YiviSpace.x24,
        ),
        action: sheet.radios
            ? SheetAction(
                key: Key(
                  sheet.multiple ? "which_card_done" : "which_card_choose",
                ),
                label: t(
                  sheet.multiple ? "share.change.done" : "share.pick.choose",
                ),
                onTap: apply,
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeading(
              title: title,
              titleKey: _title,
              // A slot that takes several: not "only needs one".
              lead: sheet.multiple
                  ? null
                  : t(
                      choice.optional
                          ? "share.pick.optional"
                          : "share.pick.one_needed",
                      {"requestor": requestor},
                    ),
            ),
            if (sheet.linked)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Text(
                  t("share.pick.linked"),
                  key: const Key("which_card_linked"),
                  style: palette.body(14).copyWith(color: palette.text),
                ),
              ),
            const SizedBox(height: YiviSpace.x16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (n, c) in children.indexed)
                    n == 0 || c is Padding
                        ? c
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: palette.divider),
                              ),
                            ),
                            child: c,
                          ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row with a radio (or a tick) at its end, top aligned with the first
/// line; [muted] greys a row that cannot be picked.
class PickRow extends StatelessWidget {
  final bool radio;
  final bool multiple;
  final bool selected;
  final bool muted;
  final VoidCallback? onTap;
  final Widget child;

  const PickRow({
    super.key,
    required this.radio,
    required this.multiple,
    required this.selected,
    this.muted = false,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Expanded(
            child: Opacity(opacity: muted ? 0.6 : 1, child: child),
          ),
          if (radio)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _Radio(selected: selected, tick: multiple),
            ),
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ColoredBox(
          color: palette.surface.withValues(alpha: 0),
          child: row,
        ),
      ),
    );
  }
}

typedef _PickRow = PickRow;

class _Radio extends StatelessWidget {
  final bool selected;
  final bool tick;
  const _Radio({required this.selected, required this.tick});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    if (tick) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? palette.link : null,
          border: selected
              ? null
              : Border.all(color: palette.faint, width: 1.5),
        ),
        child: selected
            ? Icon(Icons.check_rounded, size: 15, color: palette.onLink)
            : null,
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? palette.link : palette.faint,
          width: selected ? 6.5 : 1.5,
        ),
      ),
    );
  }
}
