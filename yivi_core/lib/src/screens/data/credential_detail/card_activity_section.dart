import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/activity_query.dart";
import "../../../models/log_entry.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../providers/activity_providers.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/date_formatter.dart";
import "../../../util/i18n.dart";
import "../../../widgets/glass/round_icon_button.dart";
import "../../../widgets/irma_close_button.dart";
import "../../../widgets/surface_card.dart";
import "../../activity/activity_detail_screen.dart";
import "../../activity/activity_entry.dart";
import "../../activity/widgets/activity_card.dart";
import "../../activity/widgets/activity_detail_parts.dart";
import "../../home/home_screen.dart";
import "../../home/widgets/home_tab.dart";

/// The Activity section of a card's details: how often it was shared, then
/// its newest entries as the Activity tab's rows (which of its fields went
/// along instead of the cards). A row
/// opens the entry as a page over the card; "See all" closes the card and
/// opens the Activity tab, asking about this card.
class CardActivitySection extends ConsumerWidget {
  final schemaless.Credential credential;

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
        return FlutterI18n.translate(context, "wallet.detail.never_shared");
      }
      final last = a.lastShared;
      return [
        "${FlutterI18n.plural(context, "wallet.detail.shared_times", a.shares)} "
            "${FlutterI18n.plural(context, "wallet.detail.with_parties", a.parties)}",
        if (last != null)
          FlutterI18n.translate(
            context,
            "wallet.detail.last_time",
            translationParams: {
              "when": activityAgo(context, last.toLocal()).toLowerCase(),
            },
          ),
      ].join(", ");
    }

    final more = activity != null && activity.total > entries.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activity != null && entries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(
              summary(),
              key: const Key("card_activity_summary"),
              style: palette.body(14).copyWith(color: palette.secondaryText),
            ),
          )
        else
          const SizedBox(height: 6),
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
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    FlutterI18n.translate(
                      context,
                      "wallet.detail.activity_empty",
                    ),
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
  final schemaless.Credential credential;
  final int total;

  const _SeeAll({required this.credential, required this.total});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    return InkWell(
      key: const Key("card_activity_see_all"),
      onTap: () {
        _askActivityTab(
          context,
          ref,
          ActivityQuery(card: ActivityCardRef.of(credential)),
        );
        // In the tablet layout the card is a pane of the Data tab, not a
        // page of its own: switching tabs is enough.
        if (!useHomePanes(context)) Navigator.of(context).maybePop();
      },
      child: SizedBox(
        height: 48,
        child: Center(
          child: Text(
            FlutterI18n.translate(
              context,
              "wallet.detail.see_all",
              translationParams: {"count": "$total"},
            ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              FlutterI18n.translate(context, "wallet.detail.added_to_yivi"),
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

/// Asks the Activity tab [query] and switches to it.
void _askActivityTab(BuildContext context, WidgetRef ref, ActivityQuery query) {
  ref.read(activityLogProvider.notifier).setFilter(query);
  context.read<HomeTabState>().add(HomeTab.activity);
}

/// Opens [log] as a page over the card: it slides in from the side, with
/// back (to the card) at the left and close (the card too) at the right.
void pushCardActivityEntry(BuildContext context, LogInfo log) {
  Navigator.of(context).push(
    // The platform's push (on iOS with the app's back swipe).
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
        _askActivityTab(context, ref, query);
        navigator.pop();
        if (!useHomePanes(context)) navigator.maybePop();
      },
      leading: RoundIconButton(
        key: const Key("card_activity_entry_back"),
        label: FlutterI18n.translate(context, "wallet.detail.back_to_card"),
        onTap: navigator.pop,
        icon: CupertinoIcons.arrow_left,
      ),
      actions: [
        IrmaCloseButton(
          key: const Key("card_activity_entry_close"),
          // Closes the card under it too.
          onTap: () => navigator
            ..pop()
            ..maybePop(),
        ),
      ],
    );
  }
}
