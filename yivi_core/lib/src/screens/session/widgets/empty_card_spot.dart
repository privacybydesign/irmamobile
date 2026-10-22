import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/yivi_palette.dart";
import "../../../widgets/credential_card/attribute_groups/attribute_value_formatting.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/card_tile.dart";
import "../../../widgets/credential_card/credential_type_thumbnail.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/glass/pill_buttons.dart";
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

/// A card that is not in the app yet: a dashed spot in the shape of the card
/// it will be, with a dashed card where that card lands, its name, and what
/// it will share, still empty ("Not in your app yet", or the value it must
/// have). When it can be added, an "Add" pill sits on its top edge, at the
/// end, where the dashed line breaks for it: the name keeps the whole line.
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

  /// "You added …, needed …" after a card with the wrong value was added.
  final String? wrong;

  /// Null when it cannot be added from Yivi.
  final VoidCallback? onTap;

  /// A finger came down on the spot, and went away without a tap (a
  /// scroll): the Change sheet moves its outline along.
  final VoidCallback? onTapDown;
  final VoidCallback? onTapCancel;

  /// Drawn with the outline of the chosen card.
  final bool selected;

  /// The types to choose from when there is more than one, shown as their
  /// own small cards in place of the dashed one (two side by side, or three
  /// and "+n"), and the title on up to three lines. The share screen only;
  /// the Change sheet shows one spot per type.
  final List<CredentialDescriptor>? kinds;

  /// Cards only accepted together: the subtitle (what to do) on up to three
  /// lines, and [kinds] are the set, not a choice.
  final bool together;

  /// The pill's label; "Add" by default ("Add both" for a set).
  final String? addLabel;

  /// Room above the dashed edge for the half of the pill that sticks out.
  static const double edgeRoom = 12;

  const EmptyCardSpot({
    super.key,
    this.landingKey,
    required this.title,
    required this.subtitle,
    this.rows = const [],
    this.requirements = const [],
    this.wrong,
    this.onTap,
    this.onTapDown,
    this.onTapCancel,
    this.selected = false,
    this.kinds,
    this.together = false,
    this.addLabel,
  });

  /// The width of a [SmallPill] with an icon, so a dashed line can leave
  /// it out.
  static double pillWidth(BuildContext context, String label) {
    final palette = YiviPalette.of(context);
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: palette.body(13, weight: FontWeight.w600),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    // SmallPill with an icon: 10 + icon 16 + 6 + text + 14.
    return (10 + 16 + 6 + text.width + 14).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final faint = palette.secondaryText.withValues(alpha: 0.75);
    final addLabel =
        this.addLabel ?? FlutterI18n.translate(context, "share.add");
    final canAdd = onTap != null;
    const pillEnd = 16.0;
    final choice = kinds != null && kinds!.length > 1 ? kinds : null;
    final tile = CardTile(
      dashed: true,
      titleMaxLines: choice == null ? 1 : 3,
      subtitleMaxLines: together ? 3 : 1,
      dashGap: canAdd
          ? (width: pillWidth(context, addLabel) + 8, fromEnd: pillEnd - 4)
          : null,
      art: choice != null
          ? SizedBox(
              key: landingKey,
              child: _KindsArt(kinds: choice),
            )
          : SizedBox(
              key: landingKey,
              width: SharedCardTile.miniWidth,
              height: SharedCardTile.miniWidth * 226 / 358,
              child: CustomPaint(
                painter: DashedCardPainter(color: palette.secondaryText),
                child: Icon(
                  canAdd ? Icons.add_rounded : Icons.block_rounded,
                  size: 18,
                  color: canAdd ? palette.link : palette.secondaryText,
                ),
              ),
            ),
      title: title,
      subtitle: subtitle,
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
        if (wrong != null)
          Text(
            wrong!,
            key: const Key("share_spot_wrong"),
            style: palette
                .body(12.5, weight: FontWeight.w600)
                .copyWith(color: palette.errorText),
          ),
      ],
    );
    final spot = Stack(
      clipBehavior: Clip.none,
      children: [
        CardTileOutline(shown: selected, child: tile),
        if (canAdd)
          PositionedDirectional(
            top: -SmallPill.height / 2,
            end: pillEnd,
            // Says what a tap does; the whole spot is the button.
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: SmallPill(
                  key: const Key("empty_spot_add"),
                  label: addLabel,
                  icon: Icons.add_rounded,
                  onPressed: onTap,
                ),
              ),
            ),
          ),
      ],
    );
    return Semantics(
      button: canAdd,
      child: Padding(
        padding: EdgeInsets.only(top: canAdd ? edgeRoom : 0),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onTapDown: onTapDown == null ? null : (_) => onTapDown!(),
          onTapCancel: onTapCancel,
          child: canAdd ? PressScale(scale: 0.98, child: spot) : spot,
        ),
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
              child: Container(
                key: const Key("empty_spot_more"),
                height: 20,
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: palette.link,
                  shape: StadiumBorder(
                    side: BorderSide(color: palette.surface, width: 2),
                  ),
                ),
                child: Text(
                  "+$more",
                  style: palette
                      .body(11, weight: FontWeight.w700)
                      .copyWith(color: Colors.white, height: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The dashed outline of a card that is not there yet.
class DashedCardPainter extends CustomPainter {
  final Color color;

  const DashedCardPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          const Radius.circular(9),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedCardPainter old) => old.color != color;
}
