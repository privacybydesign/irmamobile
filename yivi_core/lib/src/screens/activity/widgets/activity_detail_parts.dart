import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/activity_query.dart";
import "../../../models/log_entry.dart";
import "../../../providers/activity_providers.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/i18n.dart";
import "../../../widgets/centred_max_width.dart";
import "../../../widgets/compact_bar.dart";
import "../../../widgets/corner_badge.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/card_tile.dart";
import "../../../widgets/credential_card/irma_empty_credential_card.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/party_avatar.dart";
import "../../../widgets/status_chip.dart";
import "../../../widgets/surface_card.dart";
import "../activity_entry.dart";

/// The text colour of [kind] on a surface, in both themes.
Color activityKindInk(YiviPalette palette, ActivityKind kind) => switch (kind) {
  ActivityKind.shared => palette.link,
  ActivityKind.received => palette.successText,
  ActivityKind.signed => palette.heading,
  ActivityKind.deleted => palette.danger,
};

/// "Sun 11 Oct", the date on the pass header and the compact bar.
String activityShortDate(BuildContext context, DateTime time) =>
    DateFormat("EEE d MMM", context.lang).format(time);

/// The time of day ("14:05").
String activityTime(BuildContext context, DateTime time) =>
    DateFormat.jm(context.lang).format(time);

/// How many days before today [time] was (0 today, 1 yesterday).
int activityDaysAgo(DateTime time) {
  final n = DateTime.now();
  return DateTime(
    n.year,
    n.month,
    n.day,
  ).difference(DateTime(time.year, time.month, time.day)).inDays;
}

/// "Today", "Yesterday", "6 days ago", "3 weeks ago" …
String activityAgo(BuildContext context, DateTime time) {
  final days = activityDaysAgo(time);
  if (days <= 0) return FlutterI18n.translate(context, "activity.ago.today");
  if (days == 1) return FlutterI18n.translate(context, "activity.yesterday");
  if (days < 7) return FlutterI18n.plural(context, "activity.ago.days", days);
  if (days < 30) {
    return FlutterI18n.plural(context, "activity.ago.weeks", days ~/ 7);
  }
  if (days < 365) {
    return FlutterI18n.plural(context, "activity.ago.months", days ~/ 30);
  }
  return FlutterI18n.plural(context, "activity.ago.years", days ~/ 365);
}

/// The other party's logo, round as on the share screen ([PartyAvatar]).
class ActivityPartyLogo extends StatelessWidget {
  final ActivityParty party;
  final double size;

  /// A 2 pt ring around the logo, drawn inside [size], that sets it apart
  /// from the cards under it (on the hero's pile).
  final Color? ring;

  const ActivityPartyLogo({
    super.key,
    required this.party,
    required this.size,
    this.ring,
  });

  @override
  Widget build(BuildContext context) {
    final ring = this.ring;
    final avatar = PartyAvatar(
      name: party.name,
      image: party.logo,
      imagePath: party.logoPath,
      size: ring == null ? size : size - 4,
    );
    if (ring == null) return avatar;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: ring, shape: BoxShape.circle),
      child: avatar,
    );
  }
}

/// The bar's title on an entry's details once the header has gone under
/// it: the party's logo and name, and under them what happened and when
/// ("↓ Received · 1 Nov").
class ActivityBarTitle extends StatelessWidget {
  final ActivityEntry entry;

  const ActivityBarTitle({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final kind = entry.kind;
    final party = entry.party;
    final when = DateFormat.MMMd(context.lang).format(entry.localTime);
    return Semantics(
      label: party.name,
      excludeSemantics: true,
      child: Column(
        key: const Key("activity_bar_title"),
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              ActivityPartyLogo(party: party, size: 20),
              Flexible(
                child: Text(
                  party.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: palette
                      .display(15)
                      .copyWith(color: palette.text, height: 20 / 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              CornerBadge(
                icon: kind.icon,
                fill: kind.badge,
                size: 14,
                iconSize: 9,
              ),
              Flexible(
                child: Text(
                  "${FlutterI18n.translate(context, kind.labelKey)} · $when",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: palette
                      .body(12)
                      .copyWith(color: palette.secondaryText, height: 16 / 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The top of an entry's details, on the page colour: the entry's cards as
/// a large pile and the other party's logo on its corner; under it what
/// happened ("Shared with", after its icon), the party, the date and time,
/// and whether Yivi knows the party (with its website). Each fact once.
class ActivityHeroHeader extends StatelessWidget {
  final ActivityEntry entry;

  /// The band's room above the pile: it runs up under the bar and the
  /// status bar.
  final double top;

  /// On the picture (the pile), so the page can tell when it has gone
  /// under the bar (and show the party there).
  final Key? pictureKey;

  const ActivityHeroHeader({
    super.key,
    required this.entry,
    required this.top,
    this.pictureKey,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final lang = context.lang;
    final kind = entry.kind;
    final party = entry.party;
    final time = entry.localTime;
    final ink = activityKindInk(palette, kind);
    final host = party.host;
    final website = party.verified
        ? (host ?? FlutterI18n.translate(context, "missing_data.known_party"))
        : host == null
        ? FlutterI18n.translate(context, "activity.unknown_party")
        : FlutterI18n.translate(
            context,
            "activity.not_checked",
            translationParams: {"host": host},
          );

    return KeyedSubtree(
      key: const Key("activity_hero"),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, top, 16, 28),
        child: Column(
          children: [
            ActivityHeroPile(key: pictureKey, entry: entry),
            const SizedBox(height: 22),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                ExcludeSemantics(
                  child: CornerBadge(
                    icon: kind.icon,
                    fill: kind.badge,
                    size: 20,
                    iconSize: 12,
                  ),
                ),
                Flexible(
                  child: Text(
                    FlutterI18n.translate(context, kind.relationKey),
                    style: palette
                        .body(14, weight: FontWeight.w600)
                        .copyWith(color: ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Semantics(
              header: true,
              child: Text(
                party.name,
                textAlign: TextAlign.center,
                style: palette
                    .display(24, weight: FontWeight.w700)
                    .copyWith(color: palette.text, height: 30 / 24),
              ),
            ),
            const SizedBox(height: 4),
            // When, and whether Yivi knows the party, on one line (two when
            // it does not fit).
            Text.rich(
              key: const Key("activity_hero_date"),
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        "${DateFormat.yMMMd(lang).format(time)}, "
                        "${activityTime(context, time)}",
                    style: palette.body(14).copyWith(color: palette.heading),
                  ),
                  const TextSpan(text: "  ·  "),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: party.verified
                          ? Icon(
                              Icons.verified_user_rounded,
                              size: 14,
                              color: palette.successText,
                              semanticLabel: host == null
                                  ? null
                                  : FlutterI18n.translate(
                                      context,
                                      "missing_data.known_party",
                                    ),
                            )
                          : Icon(
                              Icons.shield_outlined,
                              size: 14,
                              color: palette.secondaryText,
                            ),
                    ),
                  ),
                  TextSpan(text: website),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: palette.body(13).copyWith(color: palette.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}

/// Up to three of an entry's cards as a large pile, each card behind a
/// little higher and smaller, with the other party's logo on its corner.
class ActivityHeroPile extends StatelessWidget {
  final ActivityEntry entry;

  const ActivityHeroPile({super.key, required this.entry});

  static const double width = 220;
  static const double height = 158;
  static const double cardWidth = 200;
  static const double logoSize = 64;

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
            // Back to front: the first card is on top.
            for (var i = shown - 1; i >= 0; i--)
              Positioned(
                left: (width - cardWidth) / 2,
                top: 32 - 16.0 * i,
                child: Transform.scale(
                  scale: 1 - 0.1 * i,
                  alignment: Alignment.topCenter,
                  // As shared: what did not go along is a blur.
                  child: CredentialCardArt(
                    credential: cards[i].heroArt,
                    width: cardWidth,
                    greyedOut: cards[i].deleted,
                    obscured: cards[i].unshared,
                  ),
                ),
              ),
            Positioned(
              right: -14,
              bottom: -12,
              child: ActivityPartyLogo(
                party: entry.party,
                size: logoSize,
                ring: palette.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The entry in one line, as the header of the low detail pane of a phone
/// held sideways: logo, name, and "Shared · Sun 11 Oct · 14:32".
class ActivityCompactBar extends StatelessWidget {
  final ActivityEntry entry;

  const ActivityCompactBar({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final time = entry.localTime;
    return CompactBar(
      leading: ActivityPartyLogo(party: entry.party, size: 32),
      title: entry.party.name,
      subtitle: TextSpan(
        children: [
          TextSpan(
            text: FlutterI18n.translate(context, entry.kind.labelKey),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: activityKindInk(palette, entry.kind),
            ),
          ),
          TextSpan(
            text:
                " · ${activityShortDate(context, time)}"
                " · ${activityTime(context, time)}",
          ),
        ],
      ),
    );
  }
}

/// The heading above a section's cards ("You received"), only when an
/// entry has more than one: otherwise the header says it already.
class ActivitySectionLabel extends StatelessWidget {
  final ActivityRole role;

  const ActivitySectionLabel({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          FlutterI18n.translate(context, role.titleKey),
          style: palette.display(16).copyWith(color: palette.text),
        ),
      ),
    );
  }
}

/// One card of a log entry, as a share screen tile: small card art, its
/// name and issuer, "New" or "Deleted", and the values in the log (only the
/// shared ones for a disclosure).
class ActivityCredentialTile extends StatelessWidget {
  final LogCredential credential;
  final ActivityEntryCard card;

  ActivityCredentialTile({super.key, required this.card})
    : credential = card.credential;

  @override
  Widget build(BuildContext context) {
    final chip = switch (card.role) {
      ActivityRole.received => StatusChip(
        label: FlutterI18n.translate(context, "activity.chip_new"),
        tone: DialogTone.success,
      ),
      ActivityRole.deleted => StatusChip(
        label: FlutterI18n.translate(context, "activity.kind.deleted"),
        tone: DialogTone.danger,
      ),
      _ => null,
    };
    return CardTile(
      art: CredentialCardArt(
        credential: card.art,
        width: CardTile.miniWidth,
        greyedOut: card.deleted,
      ),
      title: credential.name,
      subtitle: credential.issuer.name,
      chip: chip,
      body: [
        if (credential.attributes.isNotEmpty)
          Opacity(
            opacity: card.deleted ? 0.55 : 1,
            child: YiviCredentialCardAttributeList(
              credential.attributes,
              credentialId: credential.credentialId,
              disclosure: card.disclosure,
              showDividers: true,
            ),
          ),
      ],
    );
  }
}

/// The signed message, as a quote (when it was signed is in the header).
class ActivitySignedMessage extends StatelessWidget {
  final ActivityEntry entry;

  const ActivitySignedMessage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 28, 4, 8),
          child: Semantics(
            header: true,
            child: Text(
              FlutterI18n.translate(context, "activity.signed_message"),
              style: palette.display(16),
            ),
          ),
        ),
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote_rounded,
                size: 32,
                color: palette.outline,
              ),
              const SizedBox(height: 4),
              Text(
                entry.message ?? "",
                style: palette
                    .body(16)
                    .copyWith(height: 25 / 16, color: palette.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The line under the cards, as the shield line under the share screen's
/// cards: what stayed on the phone, or that a deletion is final. None for
/// what was received (the header says it).
class ActivityFootnote extends StatelessWidget {
  final ActivityEntry entry;

  const ActivityFootnote({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    if (entry.kind == ActivityKind.received) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              entry.kind == ActivityKind.deleted
                  ? Icons.delete_outline_rounded
                  : Icons.shield_outlined,
              size: 16,
              color: palette.secondaryText,
            ),
          ),
          Expanded(
            child: Text(
              FlutterI18n.translate(
                context,
                entry.kind.noteKey,
                translationParams: {"name": entry.party.name},
              ),
              style: palette
                  .body(13)
                  .copyWith(height: 19 / 13, color: palette.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}

/// "All activity with {party}", with how many entries there are: asks the
/// Activity tab about the party. Only when there is more than this one.
class ActivityAllWithParty extends ConsumerWidget {
  final ActivityEntry entry;
  final void Function(ActivityQuery query) onAsk;

  const ActivityAllWithParty({
    super.key,
    required this.entry,
    required this.onAsk,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final parties = ref.watch(activityPartiesProvider).value ?? const [];
    final party = entry.party;
    final summary = parties.firstWhereOrNull((p) {
      final other = ActivityParty.of(p.party);
      return other.name == party.name && other.host == party.host;
    });
    if (summary == null || summary.count < 2) return const SizedBox.shrink();
    final label = FlutterI18n.translate(
      context,
      "activity.all_with_party",
      translationParams: {"name": party.name},
    );
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SurfaceCard(
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          label: "$label, ${summary.count}",
          excludeSemantics: true,
          child: InkWell(
            key: const Key("activity_all_with_party"),
            onTap: () => onAsk(ActivityQuery(party: summary)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  spacing: 12,
                  children: [
                    Icon(Icons.history_rounded, size: 20, color: palette.link),
                    Expanded(
                      child: Text(
                        label,
                        style: palette
                            .display(16, weight: FontWeight.w500)
                            .copyWith(color: palette.link),
                      ),
                    ),
                    Text(
                      "${summary.count}",
                      style: palette
                          .body(14)
                          .copyWith(color: palette.secondaryText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Everything about a log entry, top to bottom: the hero header from edge
/// to edge, then (16 in, at most [maxWidth] wide) the signed message, the
/// cards per section, the footnote, and "All activity with …".
class ActivityDetailBody extends StatelessWidget {
  final ActivityEntry entry;

  /// The room above the hero's pile (it runs up under the bar).
  final double top;

  /// On the header's picture ([ActivityHeroHeader.pictureKey]).
  final Key? pictureKey;

  /// The compact bar as the only header, instead of the hero: in the low
  /// detail pane of a phone held sideways.
  final bool compactHeader;

  final double maxWidth;

  /// Asks the Activity tab about the party.
  final void Function(ActivityQuery query) onAsk;

  const ActivityDetailBody({
    super.key,
    required this.entry,
    required this.top,
    this.pictureKey,
    this.compactHeader = false,
    this.maxWidth = 460,
    required this.onAsk,
  });

  @override
  Widget build(BuildContext context) {
    final sections = entry.sections;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compactHeader)
          Padding(
            padding: EdgeInsets.fromLTRB(16, top, 16, 0),
            child: ActivityCompactBar(
              key: const Key("activity_detail_compact_header"),
              entry: entry,
            ),
          )
        else
          ActivityHeroHeader(entry: entry, top: top, pictureKey: pictureKey),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CentredMaxWidth(
            maxWidth: maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (entry.message != null) ActivitySignedMessage(entry: entry),
                if (sections.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    // Nothing was disclosed: one empty data card.
                    child: IrmaEmptyCredentialCard(),
                  ),
                for (final section in sections) ...[
                  if (sections.length > 1)
                    ActivitySectionLabel(role: section.role)
                  else
                    const SizedBox(height: 20),
                  for (final (i, card) in section.cards.indexed) ...[
                    if (i > 0) const SizedBox(height: 12),
                    ActivityCredentialTile(card: card),
                  ],
                ],
                ActivityFootnote(entry: entry),
                ActivityAllWithParty(entry: entry, onAsk: onAsk),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
