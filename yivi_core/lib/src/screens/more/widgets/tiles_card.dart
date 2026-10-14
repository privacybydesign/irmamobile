import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";

/// A rounded group of [Tile]s with dividers between them.
class TilesCard extends StatelessWidget {
  final List<Widget> children;

  const TilesCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return DecoratedBox(
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
      child: ClipRSuperellipse(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: Column(
          children: [
            for (var linkTile in children) ...[
              linkTile,
              if (children.last != linkTile)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 68,
                  color: palette.divider,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
