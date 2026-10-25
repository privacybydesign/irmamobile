import "package:flutter/cupertino.dart" show CupertinoPageRoute;
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/log_entry.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../providers/activity_providers.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/date_formatter.dart";
import "../../../util/i18n.dart";
import "../../../widgets/centred_max_width.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/irma_close_button.dart";
import "../../../widgets/surface_card.dart";
import "../../activity/activity_entry.dart";
import "../../activity/activity_query.dart";
import "../../activity/widgets/activity_card.dart";
import "../../activity/widgets/activity_detail_parts.dart";
import "../../home/home_screen.dart";
import "../../home/widgets/irma_nav_bar.dart";

/// The Activity section of a card's details: how often it was shared, then
/// its newest entries as rows like those of the Activity tab (who, what
/// happened in its colour, which of its fields went along, when). A row
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
          ),
        SurfaceCard(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, log) in entries.indexed)
                _CardActivityRow(
                  log: log,
                  credential: credential,
                  last: i == entries.length - 1 && !more,
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

/// One entry about the card: the other party's logo, its name, what
/// happened (in its colour) and which of the card's fields went along, and
/// when. Opens the entry as a page over the card.
class _CardActivityRow extends ConsumerWidget {
  final LogInfo log;
  final schemaless.Credential credential;
  final bool last;

  const _CardActivityRow({
    required this.log,
    required this.credential,
    required this.last,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final wallet = ref.watch(walletCardsProvider);
    final entry = ActivityEntry.fromLog(log, wallet: wallet);
    final mine = entry.cards
        .where((c) => c.credential.credentialId == credential.credentialId)
        .firstOrNull;
    final what = mine == null ? "" : describeShared(mine.credential.attributes);
    final kind = FlutterI18n.translate(context, entry.kind.labelKey);
    final when = formatActivityTimestamp(context, entry.localTime);
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: [
        entry.party.name,
        kind,
        what,
        when,
      ].where((s) => s.isNotEmpty).join(", "),
      child: InkWell(
        key: Key("card_activity_${logKey(log)}"),
        onTap: () => pushCardActivityEntry(context, log),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(bottom: BorderSide(color: palette.divider)),
          ),
          child: Row(
            spacing: 12,
            children: [
              ActivityPartyLogo(party: entry.party, size: 40),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.party.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: palette.display(15).copyWith(color: palette.text),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: kind,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: activityKindInk(palette, entry.kind),
                            ),
                          ),
                          if (what.isNotEmpty) TextSpan(text: " · $what"),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: palette.body(13).copyWith(color: palette.heading),
                    ),
                  ],
                ),
              ),
              Text(
                when,
                style: palette.body(13).copyWith(color: palette.secondaryText),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: palette.faint),
            ],
          ),
        ),
      ),
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
        ref
            .read(activityLogProvider.notifier)
            .setFilter(ActivityQuery(card: ActivityCardRef.of(credential)));
        context.read<HomeTabState>().add(IrmaNavBarTab.activity);
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

/// Opens [log] as a page over the card: it slides in from the side, with
/// back (to the card) at the left and close (the card too) at the right.
void pushCardActivityEntry(BuildContext context, LogInfo log) {
  Navigator.of(context).push(
    CupertinoPageRoute<void>(builder: (_) => _CardActivityEntryPage(log: log)),
  );
}

class _CardActivityEntryPage extends ConsumerWidget {
  final LogInfo log;

  const _CardActivityEntryPage({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final wallet = ref.watch(walletCardsProvider);
    final entry = ActivityEntry.fromLog(log, wallet: wallet);
    final navigator = Navigator.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          ListView(
            key: const Key("card_activity_entry"),
            padding: EdgeInsets.fromLTRB(
              16,
              padding.top + 76,
              16,
              padding.bottom + 32,
            ),
            children: [
              CentredMaxWidth(
                maxWidth: 460,
                child: ActivityDetailBody(entry: entry),
              ),
            ],
          ),
          Positioned(
            top: padding.top + 16,
            left: 16 + padding.left,
            right: 16 + padding.right,
            child: Row(
              children: [
                GlassIconButton(
                  key: const Key("card_activity_entry_back"),
                  semanticsLabel: FlutterI18n.translate(
                    context,
                    "wallet.detail.back_to_card",
                  ),
                  onTap: navigator.pop,
                  icon: Icon(Icons.arrow_back_rounded, color: palette.text),
                ),
                const Spacer(),
                IrmaCloseButton(
                  key: const Key("card_activity_entry_close"),
                  // Closes the card under it too.
                  onTap: () => navigator
                    ..pop()
                    ..maybePop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
