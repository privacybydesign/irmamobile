import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";

/// "+[count]" on the corner of a pile of cards: a pill [size] high (and at
/// least as wide), in [fill] with a ring in the surface colour.
class CountBadge extends StatelessWidget {
  final int count;
  final Color fill;
  final Color ink;
  final double size;
  final double fontSize;

  const CountBadge({
    super.key,
    required this.count,
    required this.fill,
    required this.ink,
    required this.size,
    required this.fontSize,
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
          side: BorderSide(color: palette.surface, width: 2),
        ),
      ),
      child: Text(
        "+$count",
        style: palette
            .body(fontSize, weight: FontWeight.w700)
            .copyWith(color: ink, height: 1),
      ),
    );
  }
}
