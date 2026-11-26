import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/credential.dart";
import "../../../models/session_state.dart";
import "../../../providers/last_shared_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../providers/wallet_cards_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/i18n.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/credential_type_thumbnail.dart";
import "../../../widgets/sheet/sheet.dart";
import "../../../widgets/sheet/sheet_actions.dart";
import "../../../widgets/sheet/sheet_heading.dart";
import "../models/disclosure_plan_view.dart";
import "disclosure_change_page.dart" show CardHead, ChangeLinkRow;
import "disclosure_value_list.dart";
import "which_card_sheet.dart" show PickRow;

/// "Welke combinatie deel je?" (2.5.2) for [choice]: one block per option,
/// complete ones first, each written out card by card; an option that can
/// still be completed has "Toevoegen" ([onAdd]) instead of a radio. A tap
/// selects; "Kies" applies; closing discards.
Future<void> showWhichCombinationSheet({
  required BuildContext context,
  required int sessionId,
  required int choice,
  required void Function(int choice, AddWay? way) onAdd,
}) => showSheet<void>(
  context: context,
  motion: SheetMotion.share,
  builder: (_) => WhichCombinationSheetView(
    key: const Key("which_combination_sheet"),
    sessionId: sessionId,
    choice: choice,
    onAdd: onAdd,
  ),
);

class WhichCombinationSheetView extends ConsumerStatefulWidget {
  final int sessionId;
  final int choice;
  final void Function(int choice, AddWay? way) onAdd;

  const WhichCombinationSheetView({
    super.key,
    required this.sessionId,
    required this.choice,
    required this.onAdd,
  });

  @override
  ConsumerState<WhichCombinationSheetView> createState() =>
      _WhichCombinationSheetState();
}

class _WhichCombinationSheetState
    extends ConsumerState<WhichCombinationSheetView> {
  /// The option picked in the sheet; -1: "Niet delen"; null: what is in use.
  int? _pick;

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
    final sheet = combinationBlocks(
      widget.choice,
      plan,
      selection,
      sharesOf: sharesOf,
    );
    final inUse =
        sheet.blocks.firstWhereOrNull((b) => b.selected)?.option ?? -1;
    final pick = _pick ?? inUse;

    void apply() {
      final n = ref.read(disclosureSelectionProvider(id).notifier);
      if (pick < 0) {
        n.share(widget.choice, on: false);
      } else {
        n.chooseOption(widget.choice, pick);
        if (choice.optional) n.share(widget.choice, on: true);
      }
      Navigator.of(context).pop();
    }

    final title = t(
      signing ? "share.combination.title_sign" : "share.combination.title",
    );
    final blocks = <Widget>[
      if (sheet.nothingRow)
        _Block(
          child: PickRow(
            key: const Key("combination_nothing"),
            radio: true,
            multiple: false,
            selected: pick < 0,
            onTap: () => setState(() => _pick = -1),
            child: Text(
              t("share.change.not_sharing"),
              style: palette
                  .display(15, weight: FontWeight.w600)
                  .copyWith(
                    color: pick < 0 ? palette.text : palette.secondaryText,
                  ),
            ),
          ),
        ),
      for (final b in sheet.blocks)
        _Block(
          child: _OptionBlock(
            key: Key("combination_option_${b.option}"),
            option: choice.options[b.option],
            block: b,
            selected: b.complete && pick == b.option,
            radio: b.complete,
            selection: selection,
            requestor: requestor,
            wallet: wallet,
            onTap: b.complete ? () => setState(() => _pick = b.option) : null,
            onAdd: b.complete
                ? null
                : () {
                    Navigator.of(context).pop();
                    widget.onAdd(
                      widget.choice,
                      addWays(
                        choice,
                      ).firstWhereOrNull((w) => w.option == b.option),
                    );
                  },
          ),
        ),
    ];

    return SheetPage.scroll(
      title: SheetTitle(title),
      padding: const EdgeInsets.fromLTRB(
        YiviSpace.x16,
        0,
        YiviSpace.x16,
        YiviSpace.x24,
      ),
      action: sheet.choose
          ? SheetAction(
              key: const Key("combination_choose"),
              label: t("share.pick.choose"),
              onTap: apply,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: YiviSpace.x8,
        children: [
          SheetHeading(
            title: title,
            lead: t(
              choice.optional ? "share.pick.optional" : "share.pick.one_needed",
              {"requestor": requestor},
            ),
          ),
          const SizedBox(height: YiviSpace.x8),
          ...blocks,
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final Widget child;
  const _Block({required this.child});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: YiviPalette.of(context).surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );
}

/// One option: its names joined with " + " and the radio, then per slot the
/// card head (picture, name, issuer) and the values of its card; missing
/// cards faded, with "Nog toevoegen" and "Toevoegen".
class _OptionBlock extends StatelessWidget {
  final DisclosureOption option;
  final CombinationBlock block;
  final bool selected;
  final bool radio;
  final DisclosureSelection selection;
  final String requestor;
  final List<Credential> wallet;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const _OptionBlock({
    super.key,
    required this.option,
    required this.block,
    required this.selected,
    required this.radio,
    required this.selection,
    required this.requestor,
    required this.wallet,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final t = context.tr;
    final names = [
      for (final s in option.slots) addableFor(s)?.name ?? slotName(s),
    ];
    return PickRow(
      radio: radio,
      multiple: false,
      selected: selected,
      muted: radio && !selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Text(
            names.join(" + "),
            style: palette
                .display(15, weight: FontWeight.w700)
                .copyWith(color: palette.text),
          ),
          for (final s in option.slots)
            if (chosenCards(s, selection).firstOrNull case final card?)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CardHead(
                    art: CredentialCardArt(
                      credential: sharedCardFor(card, wallet),
                      width: 40,
                    ),
                    name: card.name,
                    issuer: card.issuer.name,
                  ),
                  const SizedBox(height: 4),
                  DisclosureValueList(card: card, requestor: requestor),
                ],
              )
            else if (addableFor(s) case final d?)
              CardHead(
                art: Opacity(
                  opacity: 0.45,
                  child: CredentialTypeThumbnail(descriptor: d, width: 40),
                ),
                name: d.name,
                issuer: d.issuer.name,
                muted: true,
              ),
          if (!block.complete) ...[
            Text(
              t("share.combination.still_add", {
                "names": [
                  for (final s in block.missing)
                    addableFor(s)?.name ?? slotName(s),
                ].join(", "),
              }),
              style: palette.body(13).copyWith(color: palette.secondaryText),
            ),
            ChangeLinkRow(
              key: Key("combination_add_${block.option}"),
              label: t("share.combination.add"),
              disc: Icons.add_rounded,
              onTap: onAdd,
            ),
          ],
        ],
      ),
    );
  }
}
