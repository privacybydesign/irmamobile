import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/log_entry.dart";
import "../../../providers/pane_selection_provider.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../util/navigation.dart";
import "../../../widgets/corner_badge.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../activity_entry.dart";
import "../activity_query.dart";
import "activity_detail_parts.dart";

/// One log entry as a row of the Activity tab: the other party's logo with
/// a badge for what happened, the party and when, what happened (in its
/// colour) and to which cards, the cards' pictures under that, and a
/// chevron. Rows sit edge to edge on a white band, a divider between them;
/// pressed, a row turns grey.
class ActivityCard extends ConsumerWidget {
  final LogInfo logEntry;

  /// Whether the detail pane shows this entry: the row is tinted.
  final bool selected;

  /// The card the list is filtered on: the row then says which of its
  /// fields went along instead of naming the cards.
  final ActivityCardRef? focusCard;

  /// A divider under the row, from the text to the edge: all but the last
  /// row of a band.
  final bool divider;

  /// Instead of opening the entry on the Activity tab (a card's activity
  /// opens it over the card).
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.logEntry,
    this.selected = false,
    this.focusCard,
    this.divider = false,
    this.onTap,
  });

  /// The other party's logo at the start of the row.
  static const double logoSize = 44;

  /// Where the divider starts: under the text, past the logo.
  static const double dividerIndent = 16 + logoSize + 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final wallet = ref.watch(walletCardsProvider);
    final entry = ActivityEntry.fromLog(logEntry, wallet: wallet);
    final kind = entry.kind;
    final time = entry.localTime;
    final timestamp = formatActivityTimestamp(context, time);
    final titles = [for (final c in entry.cards) c.credential.name];
    final focus = focusCard;
    final focused = focus == null
        ? null
        : entry.cards.firstWhereOrNull(
            (c) =>
                c.credential.credentialId == focus.credentialId &&
                (focus.hash == null ||
                    c.credential.hash.isEmpty ||
                    c.credential.hash == focus.hash),
          );
    final shared = focused == null
        ? ""
        : describeShared(focused.credential.attributes);
    final cardsText = shared.isNotEmpty
        ? shared
        : titles.length > 2
        ? "${titles.take(2).join(", ")} +${titles.length - 2}"
        : titles.join(", ");

    return Semantics(
      label: FlutterI18n.translate(
        context,
        kind.semanticsKey,
        translationParams: {
          "otherParty": entry.party.name,
          "issuerName": entry.party.name,
          "date": timestamp,
        },
      ),
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? palette.primary.withValues(alpha: palette.isDark ? 0.22 : 0.12)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => openActivity(context, logEntry),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 40, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    ExcludeSemantics(
                      child: SizedBox.square(
                        dimension: logoSize,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ActivityPartyLogo(
                              party: entry.party,
                              size: logoSize,
                            ),
                            PositionedDirectional(
                              end: -3,
                              bottom: -3,
                              child: CornerBadge(
                                icon: kind.icon,
                                fill: kind.badge,
                                size: 20,
                                iconSize: 12,
                                ring: palette.surface,
                                ringWidth: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            spacing: 8,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.party.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: palette
                                      .display(16, weight: FontWeight.w500)
                                      .copyWith(color: palette.text),
                                ),
                              ),
                              Text(
                                timestamp,
                                style: palette
                                    .body(13)
                                    .copyWith(color: palette.secondaryText),
                              ),
                            ],
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: FlutterI18n.translate(
                                    context,
                                    kind.labelKey,
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: activityKindInk(palette, kind),
                                  ),
                                ),
                                if (cardsText.isNotEmpty)
                                  TextSpan(text: " · $cardsText"),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: palette
                                .body(14)
                                .copyWith(color: palette.heading),
                          ),
                          if (entry.cards.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: ActivityCardThumbs(entry: entry),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // The chevron, centred on the row.
              PositionedDirectional(
                end: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: palette.faint,
                  ),
                ),
              ),
              if (divider)
                PositionedDirectional(
                  start: dividerIndent,
                  end: 0,
                  bottom: 0,
                  child: Divider(height: 1, color: palette.divider),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The pictures of an entry's cards in a row, a little apart; past four,
/// a "+n".
class ActivityCardThumbs extends StatelessWidget {
  final ActivityEntry entry;

  const ActivityCardThumbs({super.key, required this.entry});

  static const double cardWidth = 34;
  static const double _gap = 4;
  static const int _max = 4;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final cards = entry.cards;
    final shown = cards.take(_max).toList();
    // Side by side, a little apart: each card reads on its own.
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: _gap,
        children: [
          for (final card in shown)
            CredentialCardArt(
              credential: card.art,
              width: cardWidth,
              greyedOut: card.deleted,
            ),
          if (cards.length > _max)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 2),
              child: Text(
                "+${cards.length - _max}",
                style: palette
                    .body(12, weight: FontWeight.w600)
                    .copyWith(color: palette.secondaryText),
              ),
            ),
        ],
      ),
    );
  }
}

/// When an entry happened, for its row: the time today, "Yesterday", or
/// else the day and month ("11 Oct").
String formatActivityTimestamp(BuildContext context, DateTime time) {
  final lang = context.lang;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final entryDay = DateTime(time.year, time.month, time.day);
  final daysAgo = today.difference(entryDay).inDays;

  if (daysAgo == 0) return DateFormat.jm(lang).format(time);
  if (daysAgo == 1) return FlutterI18n.translate(context, "activity.yesterday");
  if (time.year == now.year) return DateFormat.MMMd(lang).format(time);
  return DateFormat.yMMMd(lang).format(time);
}

/// Whether [a] and [b] are the same entry of the log (the list makes new
/// objects when it reloads).
bool sameLog(LogInfo a, LogInfo b) => logKey(a) == logKey(b);

/// Opens the details of [logEntry]: in the detail pane in the tablet layout,
/// else on a screen of its own.
void openActivity(BuildContext context, LogInfo logEntry) {
  if (useHomePanes(context)) {
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(selectedActivityProvider.notifier).select(logEntry);
    return;
  }
  context.pushActivityDetailsScreen(logInfo: logEntry);
}
