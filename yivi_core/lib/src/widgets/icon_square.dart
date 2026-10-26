import "package:material_ui/material_ui.dart";

import "../theme/yivi_edges.dart";

/// A rounded square with an [icon] (or a [child], centred) in it: the icon
/// in front of a row (36 pt), or the large tile at the top of a screen
/// (88 pt and up, `YiviCorners.iconTile`).
class IconSquare extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final Color fill;
  final Color? ink;
  final double size;

  /// Null: the icon theme's size.
  final double? iconSize;
  final double radius;

  /// An outline, e.g. [YiviEdges.block] for a tile on the page.
  final BorderSide side;

  const IconSquare({
    super.key,
    this.icon,
    this.child,
    required this.fill,
    this.ink,
    this.size = 36,
    this.iconSize = 20,
    this.radius = 12,
    this.side = BorderSide.none,
  }) : assert((icon == null) != (child == null), "an icon or a child");

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: child == null ? null : Alignment.center,
    decoration: ShapeDecoration(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        side: side,
      ),
    ),
    child: child ?? Icon(icon, size: iconSize, color: ink),
  );
}
