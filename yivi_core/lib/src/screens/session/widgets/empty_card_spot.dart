import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/yivi_palette.dart";
import "../../../widgets/credential_card/attribute_groups/attribute_value_formatting.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/credential_card/card_tile.dart";
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

/// What [card] must hold to fit the request, one line per value asked for:
/// "Nationality must be NLD". Empty when any value will do.
List<String> requirementsOf(BuildContext context, CredentialDescriptor card) =>
    [
      for (final a in card.attributes)
        if (a.requestedValue case final v? when v.hasConcreteValue)
          FlutterI18n.translate(
            context,
            "share.spot.must_be",
            translationParams: {
              "field": a.effectiveDisplayName,
              "value": localizedAttributeText(context, v) ?? "",
            },
          ),
    ];

/// A card that is not in the app yet: a dashed spot in the shape of the card
/// it will be, with a dashed card where that card lands, how to add it, and
/// what it will share, still empty. On the share screen for a required card,
/// and in the Change sheet for each type that can be added.
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

  const EmptyCardSpot({
    super.key,
    this.landingKey,
    required this.title,
    required this.subtitle,
    this.rows = const [],
    this.requirements = const [],
    this.wrong,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final faint = palette.secondaryText.withValues(alpha: 0.75);
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: CardTile(
          dashed: true,
          art: SizedBox(
            key: landingKey,
            width: SharedCardTile.miniWidth,
            height: SharedCardTile.miniWidth * 226 / 358,
            child: CustomPaint(
              painter: DashedCardPainter(color: palette.secondaryText),
              child: Icon(
                onTap == null ? Icons.block_rounded : Icons.add_rounded,
                size: 18,
                color: onTap == null ? palette.secondaryText : palette.link,
              ),
            ),
          ),
          title: title,
          subtitle: subtitle,
          trailing: onTap == null
              ? null
              // Says what a tap does; the whole spot is the button.
              : ExcludeSemantics(
                  child: SmallPill(
                    label: FlutterI18n.translate(context, "share.add"),
                    onPressed: onTap,
                  ),
                ),
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
                style: palette
                    .body(12.5)
                    .copyWith(color: palette.secondaryText),
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
        ),
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
