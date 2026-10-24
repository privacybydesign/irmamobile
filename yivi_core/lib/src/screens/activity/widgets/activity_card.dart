import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/log_entry.dart";
import "../../../providers/pane_selection_provider.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../util/navigation.dart";
import "../../../widgets/count_badge.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../data/wallet/wallet_transition.dart";
import "../activity_entry.dart";
import "../activity_flight.dart";
import "activity_detail_parts.dart";

/// One log entry as a row of the Activity tab: a small stack of its cards
/// with the other party's logo on it, the party, what happened (in its
/// colour) and to which cards, and when.
///
/// Opening it pushes the other rows away while the stack's cards fly into
/// their tiles in the details ([ActivityFlight]).
class ActivityCard extends ConsumerWidget {
  final LogInfo logEntry;

  /// Whether the detail pane shows this entry: the row gets a red border.
  final bool selected;

  const ActivityCard({
    super.key,
    required this.logEntry,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final wallet = ref.watch(walletCardsProvider);
    final entry = ActivityEntry.fromLog(logEntry, wallet: wallet);
    final kind = entry.kind;
    final time = entry.localTime;
    final timestamp = formatActivityTimestamp(context, time);
    final titles = [for (final c in entry.cards) c.credential.name];
    final cardsText = titles.length > 2
        ? "${titles.take(2).join(", ")} +${titles.length - 2}"
        : titles.join(", ");

    return PushAway(
      hash: entry.key,
      fadeWhenOpening: true,
      child: Semantics(
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
        excludeSemantics: true,
        child: PressScale(
          scale: 0.98,
          child: Material(
            color: palette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: YiviCorners.cardRadius,
              side: BorderSide(
                width: 2,
                color: selected ? palette.primary : Colors.transparent,
              ),
            ),
            shadowColor: const Color(0x17000000),
            elevation: 1,
            clipBehavior: Clip.antiAlias,
            child: Builder(
              builder: (rowContext) => InkWell(
                // A card, not a row: it gives way under the finger
                // (PressScale) instead of turning grey.
                highlightColor: Colors.transparent,
                onTap: () {
                  if (!useHomePanes(context)) {
                    WalletTransition.begin(rowContext, entry.key);
                  }
                  openActivity(context, logEntry);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    spacing: 14,
                    children: [
                      ActivityCardStack(entry: entry),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.party.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: palette
                                  .display(16)
                                  .copyWith(color: palette.text),
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
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 88),
                            child: Text(
                              timestamp,
                              textAlign: TextAlign.right,
                              style: palette
                                  .body(12)
                                  .copyWith(color: palette.heading),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Up to three of an entry's cards as a small pile, like the wallet seen
/// from the front: each card behind sits a little higher and smaller. More
/// than three get a "+n"; the other party's logo sits on the corner.
class ActivityCardStack extends StatelessWidget {
  final ActivityEntry entry;

  const ActivityCardStack({super.key, required this.entry});

  static const double width = 64;
  static const double height = 56;
  static const double cardWidth = 52;
  static const double _cardHeight =
      cardWidth *
      CredentialCardArt.designHeight /
      CredentialCardArt.designWidth;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final cards = entry.cards;
    final shown = cards.length.clamp(0, 3);
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (cards.isEmpty)
              Positioned(
                left: (width - cardWidth) / 2,
                top: 38 - _cardHeight / 2,
                child: Container(
                  width: cardWidth,
                  height: _cardHeight,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(YiviCorners.thumbnail),
                      ),
                      side: BorderSide(color: palette.outline, width: 1.5),
                    ),
                  ),
                ),
              ),
            // The cards past the third have no place in the pile; the flight
            // takes them from behind it. Their slots are measured, not shown.
            for (var i = 3; i < cards.length; i++)
              Positioned(
                left: (width - cardWidth) / 2,
                top: 22 - _cardHeight / 2,
                child: Transform.scale(
                  scale: 0.76,
                  child: ActivityFlightSlot(
                    entryKey: entry.key,
                    index: i,
                    pile: true,
                    child: const SizedBox(
                      width: cardWidth,
                      height: _cardHeight,
                    ),
                  ),
                ),
              ),
            // Back to front: the first card is on top.
            for (var i = shown - 1; i >= 0; i--)
              Positioned(
                left: (width - cardWidth) / 2,
                top: 38 - 8.0 * i - _cardHeight / 2,
                child: Transform.scale(
                  scale: 1 - 0.12 * i,
                  child: ActivityFlightSlot(
                    entryKey: entry.key,
                    index: i,
                    pile: true,
                    child: CredentialCardArt(
                      credential: cards[i].art,
                      width: cardWidth,
                      greyedOut: cards[i].deleted,
                    ),
                  ),
                ),
              ),
            if (cards.length > 3)
              Positioned(
                left: -6,
                top: 0,
                child: CountBadge(
                  count: cards.length - 3,
                  fill: palette.heading,
                  ink: palette.surface,
                  size: 18,
                  fontSize: 10,
                ),
              ),
            // Who it was with, on the corner of the pile. What happened is
            // the coloured word in the row's subtitle.
            Positioned(
              right: -8,
              bottom: -4,
              child: ActivityFlightLogoSlot(
                entryKey: entry.key,
                child: ActivityPartyLogo(
                  party: entry.party,
                  size: ActivityPartyLogo.pileSize,
                  circle: true,
                  ring: palette.surface,
                ),
              ),
            ),
          ],
        ),
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
bool sameLog(LogInfo a, LogInfo b) => a.time == b.time && a.type == b.type;

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
