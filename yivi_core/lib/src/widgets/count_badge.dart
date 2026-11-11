import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";

/// "+[count]" on the corner of a pile of cards (or "[count]" without
/// [plus], the filters on a round button): a pill [size] high (and at least
/// as wide), in [fill] with a ring in [ring], the surface colour by default.
class CountBadge extends StatelessWidget {
  final int count;
  final Color fill;
  final Color ink;
  final double size;
  final double fontSize;
  final Color? ring;
  final bool plus;

  /// The text's line height; null: the body style's own.
  final double? lineHeight;

  const CountBadge({
    super.key,
    required this.count,
    required this.fill,
    required this.ink,
    required this.size,
    required this.fontSize,
    this.ring,
    this.plus = true,
    this.lineHeight = 1,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      height: size,
      constraints: BoxConstraints(minWidth: size),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: fill,
        shape: StadiumBorder(
          side: BorderSide(color: ring ?? palette.surface, width: 2),
        ),
      ),
      child: Text(
        plus ? "+$count" : "$count",
        style: palette
            .body(fontSize, weight: FontWeight.w700)
            .copyWith(color: ink, height: lineHeight),
      ),
    );
  }
}
