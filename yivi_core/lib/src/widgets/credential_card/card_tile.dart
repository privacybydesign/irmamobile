import "package:material_ui/material_ui.dart";

import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../theme/yivi_palette.dart";
import "card_art/credential_card_art.dart";

/// A card as a tile, the way the share screen shows what is shared: small
/// card art, the name and issuer, an optional chip and trailing control, and
/// below that the values (and anything else in [body]).
///
/// Plain data only: the share screen's `SharedCardTile` and the activity
/// details both build one.
class CardTile extends StatelessWidget {
  /// Width of the small card art, at the card's 358:226 ratio.
  static const double miniWidth = 58;
  static const double miniHeight = miniWidth * 226 / 358;

  final Widget art;
  final String title;
  final String subtitle;
  final Widget? chip;
  final Widget? trailing;
  final List<Widget> body;

  /// Drawn around the tile, e.g. red for a card with a problem.
  final Color? outline;

  /// A spot for a card that is not there yet: see-through, with a dashed
  /// outline in [outline] instead of a shadow.
  final bool dashed;

  const CardTile({
    super.key,
    required this.art,
    required this.title,
    required this.subtitle,
    this.chip,
    this.trailing,
    this.body = const [],
    this.outline,
    this.dashed = false,
  });

  static const _shape = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
  );

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final decoration = dashed
        ? ShapeDecoration(
            color: palette.surface.withValues(alpha: 0.45),
            shape: _shape,
          )
        : ShapeDecoration(
            color: palette.surface,
            shape: RoundedSuperellipseBorder(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              side: outline != null
                  ? BorderSide(color: outline!, width: 1.5)
                  : BorderSide.none,
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x17000000),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          );
    return CustomPaint(
      foregroundPainter: dashed
          ? _DashedOutlinePainter(
              shape: _shape,
              color: outline ?? palette.link.withValues(alpha: 0.35),
            )
          : null,
      child: DecoratedBox(
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Row(
                spacing: 12,
                children: [
                  ExcludeSemantics(child: art),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: palette
                              .display(15)
                              .copyWith(color: palette.text),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: palette
                              .body(12.5)
                              .copyWith(color: palette.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  ?chip,
                  ?trailing,
                ],
              ),
              ...body,
            ],
          ),
        ),
      ),
    );
  }
}

/// Several cards as small card art, overlapping a little.
class CardTileMiniCards extends StatelessWidget {
  final List<schemaless.Credential> cards;

  const CardTileMiniCards({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    const w = CardTile.miniWidth;
    const h = CardTile.miniHeight;
    const step = 20.0;
    return SizedBox(
      width: w + (cards.length - 1) * step,
      height: h + (cards.length - 1) * 6,
      child: Stack(
        children: [
          for (final (i, card) in cards.indexed)
            Positioned(
              left: i * step,
              top: i * 6.0,
              child: CredentialCardArt(credential: card, width: w),
            ),
        ],
      ),
    );
  }
}

/// The small rounded label in a [CardTile] header: a problem, "Last use",
/// "New" or "Deleted".
class CardTileChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const CardTileChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: background,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: palette
            .body(12, weight: FontWeight.w700)
            .copyWith(color: foreground),
      ),
    );
  }
}

/// A dashed line along [shape], for an empty [CardTile].
class _DashedOutlinePainter extends CustomPainter {
  final ShapeBorder shape;
  final Color color;

  const _DashedOutlinePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape.getOuterPath((Offset.zero & size).deflate(0.75));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutlinePainter old) =>
      old.color != color || old.shape != shape;
}
