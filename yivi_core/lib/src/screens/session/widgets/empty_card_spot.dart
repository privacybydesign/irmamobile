import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/yivi_palette.dart";
import "../../../widgets/count_badge.dart";
import "../../../widgets/credential_card/attribute_groups/attribute_value_formatting.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/card_tile.dart";
import "../../../widgets/credential_card/credential_type_thumbnail.dart";
import "../../../widgets/dashed_outline_painter.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/press_scale.dart";
import "shared_card_tile.dart";

/// The rows of an [EmptyCardSpot] for [card]: each field the request asks
/// for, with "Not in your app yet", or "Must be {value}" when it needs one.
///
/// Only the fields with a requested value: for IRMA requests irmago lists the
/// whole type in the descriptor and marks the requested ones.
List<(String, String)> emptySpotRows(
  BuildContext context,
  CredentialDescriptor card,
) {
  String rowValue(schemaless.Attribute a) {
    final v = a.requestedValue;
    return v != null && v.hasConcreteValue
        ? FlutterI18n.translate(
            context,
            "share.spot.must_be_value",
            translationParams: {
              "value": localizedAttributeText(context, v) ?? "",
            },
          )
        : FlutterI18n.translate(context, "share.not_in_app_yet");
  }

  return [
    for (final a in card.attributes)
      if (a.requestedValue != null) (a.effectiveDisplayName, rowValue(a)),
  ];
}

/// A card that is not in the app yet: a dashed [CardTile] with a dashed
/// outline where the card will land (or the types to choose from, [kinds]),
/// its name, and what it will share, still empty ("Not in your app yet", or
/// the value it must have). When it can be added, a strip at its foot says
/// to add it first, with an "Add" pill: the same strip a card with a choice
/// has, with "Change choice".
///
/// The one widget for this: on the share screen for a required card, and in
/// the Change sheet for each type that can be added.
class EmptyCardSpot extends StatelessWidget {
  final GlobalKey? landingKey;
  final String title;
  final String subtitle;

  /// What the request asks of the card: label and "Not in your app yet"
  /// (or the value it must have).
  final List<(String, String)> rows;

  /// "{field} must be {value}" for each value the request needs, when there
  /// are no [rows] to show them in.
  final List<String> requirements;

  /// Null when it cannot be added from Yivi.
  final VoidCallback? onTap;

  /// The types to choose from when there is more than one, shown as their
  /// own small cards in place of the dashed one (two side by side, or three
  /// and "+n"), and the title on up to three lines. The Change sheet passes
  /// them only for a set of cards that go together ([together]); otherwise
  /// it shows one spot per type.
  final List<CredentialDescriptor>? kinds;

  /// Cards only accepted together: the subtitle (what to do) on up to three
  /// lines, and [kinds] are the set, not a choice.
  final bool together;

  /// The pill's label; "Add" by default ("Add both" for a set).
  final String? addLabel;

  const EmptyCardSpot({
    super.key,
    this.landingKey,
    required this.title,
    required this.subtitle,
    this.rows = const [],
    this.requirements = const [],
    this.onTap,
    this.kinds,
    this.together = false,
    this.addLabel,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final faint = palette.secondaryText.withValues(alpha: 0.75);
    final addLabel =
        this.addLabel ?? FlutterI18n.translate(context, "share.add");
    final canAdd = onTap != null;
    final choice = kinds != null && kinds!.length > 1 ? kinds : null;
    final tile = CardTile(
      dashed: true,
      titleMaxLines: choice == null ? 1 : 3,
      subtitleMaxLines: together ? 3 : 1,
      art: choice != null
          ? SizedBox(
              key: landingKey,
              child: _KindsArt(kinds: choice),
            )
          : SizedBox(
              key: landingKey,
              width: SharedCardTile.miniWidth,
              height: CardTile.miniHeight,
              child: CustomPaint(
                painter: DashedOutlinePainter(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(9)),
                  ),
                  color: palette.secondaryText.withValues(alpha: 0.6),
                  dash: 4,
                  period: 7,
                ),
                child: Icon(
                  canAdd ? Icons.add_rounded : Icons.block_rounded,
                  size: 18,
                  color: canAdd ? palette.link : palette.secondaryText,
                ),
              ),
            ),
      title: title,
      subtitle: subtitle,
      footer: canAdd
          ? CardTileStrip(
              children: [
                Expanded(
                  child: Text(
                    FlutterI18n.translate(context, "share.spot.add_first"),
                    style: CardTileStrip.textStyle(context),
                  ),
                ),
                // Says what a tap does; the whole spot is the button.
                SmallPill(
                  key: const Key("empty_spot_add"),
                  label: addLabel,
                  tone: SmallPillTone.surface,
                  onPressed: onTap,
                ),
              ],
            )
          : null,
      body: [
        if (rows.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (n, (label, value)) in rows.indexed)
                Container(
                  decoration: BoxDecoration(
                    border: n == 0
                        ? null
                        : Border(top: BorderSide(color: palette.divider)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: attributeLabelStyle(context)),
                      Text(
                        value,
                        style: attributeValueStyle(
                          context,
                          faint,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        for (final r in requirements)
          Text(
            r,
            style: palette.body(12.5).copyWith(color: palette.secondaryText),
          ),
      ],
    );
    return Semantics(
      button: canAdd,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: PressScale(scale: PressScale.card, enabled: canAdd, child: tile),
      ),
    );
  }
}

/// The types an empty spot can be filled with, as their own cards, faded:
/// two overlapping, or the first three stacked with "+n" for the rest.
class _KindsArt extends StatelessWidget {
  final List<CredentialDescriptor> kinds;

  const _KindsArt({required this.kinds});

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final two = kinds.length == 2;
    final shown = kinds.take(two ? 2 : 3).toList();
    final more = kinds.length - shown.length;
    final width = two ? 46.0 : 42.0;
    Widget card(int i, CredentialDescriptor d) {
      final (x, y, alpha) = two
          ? (i * 12.0, i * 14.0, i == 0 ? 0.45 : 0.7)
          : (i * 7.0, i * 7.0, 0.4 + 0.25 * i);
      return Positioned(
        left: x,
        top: y,
        // A thin ring in the card's colour keeps the cards apart.
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: palette.surface,
            shape: RoundedRectangleBorder(
              borderRadius:
                  CredentialCardArt.radiusFor(width) +
                  const BorderRadius.all(Radius.circular(1.5)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: Opacity(
              opacity: alpha,
              child: CredentialTypeThumbnail(descriptor: d, width: width),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: SharedCardTile.miniWidth,
      height: _height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (i, d) in shown.indexed) card(i, d),
          if (more > 0)
            Positioned(
              right: -4,
              bottom: -2,
              child: CountBadge(
                key: const Key("empty_spot_more"),
                count: more,
                fill: palette.link,
                ink: Colors.white,
                size: 20,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}
