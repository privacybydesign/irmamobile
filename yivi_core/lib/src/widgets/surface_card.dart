import "package:material_ui/material_ui.dart";

import "../theme/yivi_corners.dart";
import "../theme/yivi_edges.dart";
import "../theme/yivi_palette.dart";

/// A white card around [child]: the surface colour and the card corner,
/// flat ([decoration]). With [clipBehavior] the child is clipped to the
/// corners.
class SurfaceCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;

  const SurfaceCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    margin: margin,
    padding: padding,
    alignment: alignment,
    clipBehavior: clipBehavior,
    decoration: decoration(context),
    child: child,
  );

  /// The look of a [SurfaceCard], for a box that draws its own: the surface
  /// colour in the card corner, outlined with Increase Contrast.
  static ShapeDecoration decoration(BuildContext context) => ShapeDecoration(
    color: YiviPalette.of(context).surface,
    shape: RoundedRectangleBorder(
      borderRadius: YiviCorners.cardRadius,
      side: YiviEdges.block(context),
    ),
  );
}
