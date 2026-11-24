import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/activity_query.dart";
import "../../../models/credential.dart";
import "../../../models/log_entry.dart";
import "../../../providers/activity_providers.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/date_formatter.dart";
import "../../../util/i18n.dart";
import "../../../widgets/buttons/close_button.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/surfaces/surface_card.dart";
import "../../activity/activity_detail_screen.dart";
import "../../activity/activity_entry.dart";
import "../../activity/widgets/activity_card.dart";
import "../../activity/widgets/activity_detail_parts.dart";
import "../../home/widgets/home_tab.dart";
import "../card_transition/card_transition.dart";
import "../wallet/wallet_detail_scaffold.dart";

/// The Activity section of a card's details: how often it was shared, then
/// its newest entries as the Activity tab's rows (which of its fields went
/// along instead of the cards). A row
/// opens the entry as a page over the card; "See all" closes the card and
/// opens the Activity tab, asking about this card.
class CardActivitySection extends ConsumerWidget {
  final Credential credential;

  const CardActivitySection({super.key, required this.credential});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final activity = ref.watch(cardActivityProvider(credential.hash)).value;
    final entries = activity?.entries ?? const <LogInfo>[];
    final issued = credential.issuanceDate == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(credential.issuanceDate! * 1000);

    String summary() {
      final a = activity!;
      if (a.shares == 0) {
        return context.tr("wallet.detail.never_shared");
      }
      final last = a.lastShared;
      return [
        "${context.plural("wallet.detail.shared_times", a.shares)} "
            "${context.plural("wallet.detail.with_parties", a.parties)}",
        if (last != null)
          context.tr("wallet.detail.last_time", {
            "when": activityAgo(context, last.toLocal()).toLowerCase(),
          }),
      ].join(", ");
    }

    final more = activity != null && activity.total > entries.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activity != null && entries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              YiviSpace.x4,
              0,
              YiviSpace.x4,
              YiviSpace.x12,
            ),
            child: Text(
              summary(),
              key: const Key("card_activity_summary"),
              style: palette.body(14).copyWith(color: palette.secondaryText),
            ),
          )
        else
          const SizedBox(height: YiviSpace.x8),
        SurfaceCard(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, log) in entries.indexed)
                ActivityCard(
                  key: Key("card_activity_${logKey(log)}"),
                  logEntry: log,
                  focusCard: ActivityCardRef.of(credential),
                  divider: i < entries.length - 1 || more,
                  onTap: () => pushCardActivityEntry(context, log),
                ),
              if (more) _SeeAll(credential: credential, total: activity.total),
              // A card whose issuance is not in the log: when it was added.
              if (entries.isEmpty && issued != null)
                _AddedRow(date: printableDate(issued, context.lang)),
              if (entries.isEmpty && issued == null)
                Padding(
                  padding: const EdgeInsets.all(YiviSpace.x16),
                  child: Text(
                    context.tr("wallet.detail.activity_empty"),
                    style: palette
                        .body(13)
                        .copyWith(color: palette.secondaryText),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "See all (7)": closes the card and opens the Activity tab, asking about
/// this card, where the question can be narrowed further.
class _SeeAll extends ConsumerWidget {
  final Credential credential;
  final int total;

  const _SeeAll({required this.credential, required this.total});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    return InkWell(
      key: const Key("card_activity_see_all"),
      onTap: () => _askActivityTab(
        context,
        ref,
        ActivityQuery(card: ActivityCardRef.of(credential)),
      ),
      child: SizedBox(
        height: 48,
        child: Center(
          child: Text(
            context.tr("wallet.detail.see_all", {"count": "$total"}),
            style: palette
                .body(15)
                .copyWith(fontWeight: FontWeight.w600, color: palette.link),
          ),
        ),
      ),
    );
  }
}

class _AddedRow extends StatelessWidget {
  final String date;

  const _AddedRow({required this.date});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        YiviSpace.x16,
        YiviSpace.x12,
        YiviSpace.x16,
        YiviSpace.x12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr("wallet.detail.added_to_yivi"),
              style: palette
                  .body(14)
                  .copyWith(fontWeight: FontWeight.w600, color: palette.text),
            ),
          ),
          Text(
            date,
            style: palette.body(13).copyWith(color: palette.secondaryText),
          ),
        ],
      ),
    );
  }
}

/// Asks the Activity tab [query], switches to it, and closes the card: at
/// once, without flying back to a tab that is no longer shown. In the
/// tablet layout the card is a pane of the Data tab, not a page of its own:
/// switching tabs is enough.
void _askActivityTab(BuildContext context, WidgetRef ref, ActivityQuery query) {
  // Taken before the tab switches, which ends the card's transition.
  final transition = _openCard(context);
  final panes = useHomePanes(context);
  final navigator = Navigator.of(context);
  ref.read(activityLogProvider.notifier).setFilter(query);
  ref.read(homeTabProvider.notifier).select(HomeTab.activity);
  if (panes) return;
  if (transition != null) return transition.dismiss();
  navigator.maybePop();
}

/// The card transition the details are part of, if they are.
CardTransition? _openCard(BuildContext context) =>
    CardTransitionScope.maybeOf(context)?.current.value;

/// Opens [log] as a page over the card: it slides in from the side, with
/// back (to the card) at the left and close (the card too) at the right.
void pushCardActivityEntry(BuildContext context, LogInfo log) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => _CardActivityEntryPage(log: log)),
  );
}

class _CardActivityEntryPage extends ConsumerWidget {
  final LogInfo log;

  const _CardActivityEntryPage({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigator = Navigator.of(context);
    return ActivityDetailPage(
      key: const Key("card_activity_entry"),
      log: log,
      // Closes the entry and the card, and asks the Activity tab.
      onAsk: (query) {
        navigator.pop();
        _askActivityTab(context, ref, query);
      },
      leading: YiviIconButton(
        key: const Key("card_activity_entry_back"),
        label: context.tr("wallet.detail.back_to_card"),
        onTap: navigator.pop,
        icon: CupertinoIcons.arrow_left,
        look: IconButtonLook.bar,
      ),
      actions: [
        YiviCloseButton(
          key: const Key("card_activity_entry_close"),
          // Closes the card under it too. Next to a pane the card is the
          // pane's pick, not a page: only the entry closes.
          onTap: () {
            final transition = _openCard(context);
            final panes = useHomePanes(context);
            navigator.pop();
            if (!panes) closeCardDetails(context, transition);
          },
        ),
      ],
    );
  }
}
