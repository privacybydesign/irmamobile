import "package:flutter_i18n/flutter_i18n.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/log_entry.dart";
import "../../../theme/yivi_edges.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/i18n.dart";
import "../../../widgets/caps_label.dart";
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
import "../../data/wallet/wallet_detail_scaffold.dart";
import "../activity_entry.dart";
import "../activity_flight.dart";

/// The text colour of [kind] on a surface, in both themes.
Color activityKindInk(YiviPalette palette, ActivityKind kind) => switch (kind) {
  ActivityKind.shared => palette.link,
  ActivityKind.received => palette.successText,
  ActivityKind.signed => palette.heading,
  ActivityKind.deleted => palette.danger,
};

String _lang(BuildContext context) => context.lang;

/// "Sun 11 Oct", the date on the pass header and the compact bar.
String activityShortDate(BuildContext context, DateTime time) =>
    DateFormat("EEE d MMM", _lang(context)).format(time);

String activityTime(BuildContext context, DateTime time) =>
    DateFormat.jm(_lang(context)).format(time);

/// "Today", "Yesterday", "6 days ago", "3 weeks ago" …
String activityAgo(BuildContext context, DateTime time) {
  final n = DateTime.now();
  final days = DateTime(
    n.year,
    n.month,
    n.day,
  ).difference(DateTime(time.year, time.month, time.day)).inDays;
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

  /// Its size as the badge on a row's pile.
  static const double pileSize = 30;

  /// A 2 pt ring around the logo, drawn inside [size], that sets it apart
  /// from the cards under it, e.g. as the badge on a row's pile.
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

/// The top of the details, centred: the other party's logo with a badge for
/// what happened, "Shared with" in that colour, its name, whether Yivi knows
/// it, and when it happened as a date and a time pill.
class ActivityPartyCard extends StatelessWidget {
  final ActivityEntry entry;

  const ActivityPartyCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final lang = _lang(context);
    final kind = entry.kind;
    final party = entry.party;
    final time = entry.localTime;
    final fullDate = DateFormat.yMMMMEEEEd(lang).format(time);
    final clock = activityTime(context, time);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: 80,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ActivityPartyLogo(party: party, size: 80),
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: CornerBadge(
                      icon: kind.icon,
                      fill: kind.badge,
                      size: 32,
                      iconSize: 15,
                      ring: palette.background,
                      ringWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            FlutterI18n.translate(context, kind.relationKey),
            textAlign: TextAlign.center,
            style: palette
                .body(14, weight: FontWeight.w600)
                .copyWith(color: activityKindInk(palette, kind)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Semantics(
              header: true,
              child: Text(
                party.name,
                textAlign: TextAlign.center,
                style: palette
                    .display(26, weight: FontWeight.w700)
                    .copyWith(color: palette.heading, height: 32 / 26),
              ),
            ),
          ),
          if (party.verified || party.host != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  if (party.verified)
                    Icon(
                      Icons.verified_user_rounded,
                      size: 14,
                      color: palette.successText,
                      semanticLabel: FlutterI18n.translate(
                        context,
                        "missing_data.known_party",
                      ),
                    ),
                  Flexible(
                    child: Text(
                      party.host ??
                          FlutterI18n.translate(
                            context,
                            "missing_data.known_party",
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: palette
                          .body(13)
                          .copyWith(color: palette.secondaryText),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderPill(
                key: const Key("activity_date_pill"),
                icon: Icons.calendar_month_rounded,
                label: fullDate,
              ),
              _HeaderPill(
                key: const Key("activity_time_pill"),
                icon: Icons.schedule_rounded,
                label: clock,
                strong: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            activityAgo(context, time),
            style: palette.body(12).copyWith(color: palette.secondaryText),
          ),
        ],
      ),
    );
  }
}

/// A white pill with an icon, for the date and the time in the header.
class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Bold, with figures of equal width (the time).
  final bool strong;

  const _HeaderPill({
    super.key,
    required this.icon,
    required this.label,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        // At least 40 high; a date too long for the width wraps instead of
        // running out of the pill.
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
        decoration: ShapeDecoration(
          color: palette.surface,
          shape: StadiumBorder(side: YiviEdges.block(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Icon(icon, size: 18, color: palette.secondaryText),
            Flexible(
              child: Text(
                label,
                style: palette
                    .body(
                      14,
                      weight: strong ? FontWeight.w700 : FontWeight.w600,
                    )
                    .copyWith(
                      color: palette.text,
                      fontFeatures: strong
                          ? const [FontFeature.tabularFigures()]
                          : null,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The entry in one line, for the glass bar once the header has scrolled
/// away: logo, name, and "Shared · Sun 11 Oct · 14:32".
class ActivityCompactBar extends StatelessWidget {
  final ActivityEntry entry;
  final double opacity;

  const ActivityCompactBar({
    super.key,
    required this.entry,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final time = entry.localTime;
    return GlassCompactBar(
      opacity: opacity,
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

/// The small uppercase label above a section's cards, as on the share
/// screen ("You shared").
class ActivitySectionLabel extends StatelessWidget {
  final ActivityRole role;

  const ActivitySectionLabel({super.key, required this.role});

  @override
  Widget build(BuildContext context) => CapsLabel(
    FlutterI18n.translate(context, role.titleKey),
    padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
  );
}

/// One card of a log entry, as a share screen tile: small card art, its
/// name and issuer, "New" or "Deleted", and the values in the log (only the
/// shared ones for a disclosure).
class ActivityCredentialTile extends StatelessWidget {
  final LogCredential credential;
  final ActivityEntryCard card;

  /// The art, e.g. in an [ActivityFlightSlot].
  final Widget art;

  ActivityCredentialTile({super.key, required this.card, required this.art})
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
      art: art,
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

/// The signed message, as a quote, with when it was signed.
class ActivitySignedMessage extends StatelessWidget {
  final ActivityEntry entry;

  const ActivitySignedMessage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final time = entry.localTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
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
              const SizedBox(height: 16),
              Divider(height: 1, color: palette.divider),
              const SizedBox(height: 12),
              Row(
                spacing: 6,
                children: [
                  Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: palette.secondaryText,
                  ),
                  Expanded(
                    child: Text(
                      FlutterI18n.translate(
                        context,
                        "activity.signed_by_you",
                        translationParams: {
                          "date": activityShortDate(context, time),
                          "time": activityTime(context, time),
                        },
                      ),
                      style: palette
                          .body(12)
                          .copyWith(color: palette.secondaryText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The line at the end of the details, as the shield line under the share
/// screen's cards.
class ActivityFootnote extends StatelessWidget {
  final ActivityEntry entry;

  const ActivityFootnote({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
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

/// Everything about a log entry, top to bottom: the pass header, the signed
/// message, the cards per section and the footnote. Each part fades up with
/// [animation]; with [heroes], the card arts fly in from the activity row.
class ActivityDetailBody extends StatelessWidget {
  final ActivityEntry entry;
  final Animation<double> animation;

  /// The card arts are the slots of [ActivityFlight] (the details screen).
  final bool flight;

  /// Called on a tap on a card's art (back to the activity list).
  final VoidCallback? onArtTap;

  /// On the header, so the details screen can tell when it has scrolled
  /// away (and show the compact bar).
  final Key? headerKey;

  /// The compact bar as the only header, instead of the big one: in the low
  /// detail pane of a phone held sideways.
  final bool compactHeader;

  const ActivityDetailBody({
    super.key,
    required this.entry,
    this.animation = kAlwaysCompleteAnimation,
    this.flight = false,
    this.onArtTap,
    this.headerKey,
    this.compactHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget reveal(Widget child) =>
        WalletReveal(animation: animation, child: child);
    var index = 0;
    Widget art(int i) {
      final card = entry.cards[i];
      final art = CredentialCardArt(
        credential: card.art,
        width: CardTile.miniWidth,
        greyedOut: card.deleted,
      );
      final picture = flight
          ? ActivityFlightSlot(
              entryKey: entry.key,
              index: i,
              pile: false,
              child: art,
            )
          : art;
      if (onArtTap == null) return picture;
      return Semantics(
        button: true,
        label: FlutterI18n.translate(context, "activity.back_to_activity"),
        child: GestureDetector(onTap: onArtTap, child: picture),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compactHeader)
          reveal(
            ActivityCompactBar(
              key: const Key("activity_detail_compact_header"),
              entry: entry,
              opacity: 1,
            ),
          )
        else
          reveal(ActivityPartyCard(key: headerKey, entry: entry)),
        if (entry.message != null) reveal(ActivitySignedMessage(entry: entry)),
        if (entry.sections.isEmpty)
          reveal(
            Padding(
              padding: const EdgeInsets.only(top: 24),
              // Nothing was disclosed: one empty data card.
              child: IrmaEmptyCredentialCard(),
            ),
          ),
        for (final section in entry.sections) ...[
          reveal(ActivitySectionLabel(role: section.role)),
          for (final (i, card) in section.cards.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            reveal(ActivityCredentialTile(card: card, art: art(index++))),
          ],
        ],
        reveal(ActivityFootnote(entry: entry)),
      ],
    );
  }
}
