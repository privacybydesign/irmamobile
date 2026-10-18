import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/log_entry.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/card_tile.dart";
import "../../../widgets/credential_card/irma_empty_credential_card.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../data/wallet/wallet_detail_scaffold.dart";
import "../../data/wallet/wallet_transition.dart";
import "../activity_entry.dart";

/// The text colour of [kind] on a surface, in both themes.
Color activityKindInk(YiviPalette palette, ActivityKind kind) => switch (kind) {
  ActivityKind.shared => palette.link,
  ActivityKind.received => palette.successText,
  ActivityKind.signed => palette.heading,
  ActivityKind.deleted => palette.danger,
};

String _lang(BuildContext context) =>
    FlutterI18n.currentLocale(context)?.languageCode ?? "en";

/// "Sun 11 Oct", the date on the pass header and the compact bar.
String activityShortDate(BuildContext context, DateTime time) =>
    DateFormat("EEE d MMM", _lang(context)).format(time);

String activityTime(BuildContext context, DateTime time) =>
    DateFormat.jm(_lang(context)).format(time);

/// "Today", "Yesterday", "6 days ago", "3 weeks ago" …
String activityAgo(BuildContext context, DateTime time, {DateTime? now}) {
  final n = now ?? DateTime.now();
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

/// The other party's logo on a rounded tile, or its first letter.
class ActivityPartyLogo extends StatelessWidget {
  final ActivityParty party;
  final double size;

  const ActivityPartyLogo({super.key, required this.party, required this.size});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final logo = party.logo;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: logo == null ? palette.tint : palette.surface,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(size * 0.3)),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: logo != null
          ? SizedBox.square(
              dimension: size * 0.66,
              child: Base64Image(base64: logo.base64, mimeType: logo.mimeType),
            )
          : Text(
              party.name.isEmpty ? "?" : party.name.characters.first,
              style: palette
                  .display(size * 0.43, weight: FontWeight.w700)
                  .copyWith(color: palette.link),
            ),
    );
  }
}

/// The top of the details, shaped like a ticket: the other party on a band
/// in the colour of what happened, a perforated line, then what happened,
/// the date and the time as three fields.
class ActivityPartyCard extends StatelessWidget {
  final ActivityEntry entry;

  const ActivityPartyCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final kind = entry.kind;
    final party = entry.party;
    final time = entry.localTime;
    final ink = activityKindInk(palette, kind);
    // What the kind is about: the received cards of an issuance, not what
    // was shared to get them.
    final count = entry.sections.firstOrNull?.cards.length ?? 0;
    const shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(Radius.circular(28)),
    );

    return DecoratedBox(
      key: const Key("activity_party_card"),
      decoration: const ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: Color(0x17000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipPath(
        clipper: const ShapeBorderClipper(shape: shape),
        child: ColoredBox(
          color: palette.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: Color.alphaBlend(
                  kind.badge.withValues(alpha: 0.09),
                  palette.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Row(
                    spacing: 16,
                    children: [
                      ExcludeSemantics(
                        child: ActivityPartyLogo(party: party, size: 60),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FlutterI18n.translate(context, kind.relationKey),
                              style: palette
                                  .body(13)
                                  .copyWith(color: palette.secondaryText),
                            ),
                            Semantics(
                              header: true,
                              child: Text(
                                party.name,
                                style: palette
                                    .display(20, weight: FontWeight.w700)
                                    .copyWith(color: palette.text),
                              ),
                            ),
                            if (party.verified || party.host != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
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
                                            .body(12)
                                            .copyWith(color: palette.heading),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _Perforation(notch: palette.background, line: palette.outline),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    Expanded(
                      flex: 105,
                      child: _PassField(
                        label: FlutterI18n.translate(context, kind.labelKey),
                        labelColor: ink,
                        icon: kind.icon,
                        value: FlutterI18n.plural(
                          context,
                          "activity.cards",
                          count,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 145,
                      child: _PassField(
                        label: FlutterI18n.translate(context, "activity.date"),
                        value: activityShortDate(context, time),
                        below: "${time.year} · ${activityAgo(context, time)}",
                      ),
                    ),
                    Expanded(
                      flex: 80,
                      child: _PassField(
                        label: FlutterI18n.translate(context, "activity.time"),
                        value: activityTime(context, time),
                        large: true,
                        end: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dashed line across the card with a round notch at each edge.
class _Perforation extends StatelessWidget {
  final Color notch;
  final Color line;

  const _Perforation({required this.notch, required this.line});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 2,
    child: CustomPaint(painter: _PerforationPainter(notch, line)),
  );
}

class _PerforationPainter extends CustomPainter {
  final Color notch;
  final Color line;

  _PerforationPainter(this.notch, this.line);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final dash = Paint()
      ..color = line
      ..strokeWidth = 2;
    for (var x = 22.0; x < size.width - 22; x += 10) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + 5).clamp(0, size.width - 22), y),
        dash,
      );
    }
    final fill = Paint()..color = notch;
    canvas.drawCircle(Offset(0, y), 11, fill);
    canvas.drawCircle(Offset(size.width, y), 11, fill);
  }

  @override
  bool shouldRepaint(_PerforationPainter old) =>
      old.notch != notch || old.line != line;
}

class _PassField extends StatelessWidget {
  final String label;
  final Color? labelColor;
  final IconData? icon;
  final String value;
  final String? below;
  final bool large;
  final bool end;

  const _PassField({
    required this.label,
    this.labelColor,
    this.icon,
    required this.value,
    this.below,
    this.large = false,
    this.end = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final color = labelColor ?? palette.secondaryText;
    return Column(
      crossAxisAlignment: end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (icon != null) Icon(icon, size: 12, color: color),
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: palette
                    .body(11, weight: FontWeight.w700)
                    .copyWith(
                      color: color,
                      letterSpacing: 0.9,
                      height: 16 / 11,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: end ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: palette
                .display(
                  large ? 22 : 16,
                  weight: large ? FontWeight.w700 : FontWeight.w600,
                )
                .copyWith(
                  color: palette.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ),
        if (below != null)
          Text(
            below!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: palette.body(12).copyWith(color: palette.secondaryText),
          ),
      ],
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
    return GlassSurface(
      opacity: opacity,
      padding: const EdgeInsets.fromLTRB(6, 0, 16, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          spacing: 8,
          children: [
            ActivityPartyLogo(party: entry.party, size: 32),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.party.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: palette.display(14).copyWith(color: palette.text),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: FlutterI18n.translate(
                            context,
                            entry.kind.labelKey,
                          ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: palette
                        .body(12)
                        .copyWith(color: palette.secondaryText),
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

/// The small uppercase label above a section's cards, as on the share
/// screen ("You shared").
class ActivitySectionLabel extends StatelessWidget {
  final ActivityRole role;

  const ActivitySectionLabel({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
      child: Semantics(
        header: true,
        child: Text(
          FlutterI18n.translate(context, role.titleKey).toUpperCase(),
          style: palette
              .body(12.5, weight: FontWeight.w700)
              .copyWith(color: palette.secondaryText, letterSpacing: 0.6),
        ),
      ),
    );
  }
}

/// The card art of the [index]th card of an entry as a hero: it flies
/// between the stack in the activity row and the tile in the details.
class ActivityCardHero extends StatelessWidget {
  final ActivityEntry entry;
  final int index;
  final double width;

  const ActivityCardHero({
    super.key,
    required this.entry,
    required this.index,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final card = entry.cards[index];
    return Hero(
      tag: entry.heroTag(index),
      createRectTween: WalletTransition.staggeredRectTween(index),
      // Drawn at the size of the flight, so it stays sharp.
      flightShuttleBuilder: (_, _, _, _, _) => LayoutBuilder(
        builder: (context, constraints) => CredentialCardArt(
          credential: card.art,
          width: constraints.maxWidth,
          greyedOut: card.deleted,
        ),
      ),
      child: CredentialCardArt(
        credential: card.art,
        width: width,
        greyedOut: card.deleted,
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

  /// The art, e.g. an [ActivityCardHero].
  final Widget art;

  ActivityCredentialTile({super.key, required this.card, required this.art})
    : credential = card.credential;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final chip = switch (card.role) {
      ActivityRole.received => CardTileChip(
        label: FlutterI18n.translate(context, "activity.chip_new"),
        background: palette.successSurface,
        foreground: palette.successText,
      ),
      ActivityRole.deleted => CardTileChip(
        label: FlutterI18n.translate(context, "activity.kind.deleted"),
        background: palette.errorSurface,
        foreground: palette.errorText,
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
        DecoratedBox(
          decoration: ShapeDecoration(
            color: palette.surface,
            shape: const RoundedSuperellipseBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x17000000),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
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
  final bool heroes;

  /// Called on a tap on a card's art (back to the activity list).
  final VoidCallback? onArtTap;

  const ActivityDetailBody({
    super.key,
    required this.entry,
    this.animation = kAlwaysCompleteAnimation,
    this.heroes = false,
    this.onArtTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget reveal(Widget child) =>
        WalletReveal(animation: animation, child: child);
    var index = 0;
    Widget art(int i) {
      final card = entry.cards[i];
      final picture = heroes
          ? ActivityCardHero(entry: entry, index: i, width: CardTile.miniWidth)
          : CredentialCardArt(
              credential: card.art,
              width: CardTile.miniWidth,
              greyedOut: card.deleted,
            );
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
        reveal(ActivityPartyCard(entry: entry)),
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
