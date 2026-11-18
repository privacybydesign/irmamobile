import "package:material_ui/material_ui.dart";

import "../../theme/yivi_corners.dart";
import "../../theme/yivi_edges.dart";
import "../../theme/yivi_palette.dart";

/// A white card around [child]: the surface colour and the card corner,
/// flat ([decoration]). With [clipBehavior] the child is clipped to the
/// corners. With [onTap] it is pressable and lights up grey under the
/// finger, as rows do; [selected] gives it the 2 pt primary edge of a
/// picked card.
class SurfaceCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final VoidCallback? onTap;
  final bool selected;

  const SurfaceCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.none,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final onTap = this.onTap;
    if (onTap == null) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        alignment: alignment,
        clipBehavior: clipBehavior,
        decoration: decoration(context, selected: selected),
        child: child,
      );
    }
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Material(
        color: YiviPalette.of(context).surface,
        shape: shape(context, selected: selected),
        clipBehavior: Clip.antiAlias,
        // The theme's grey press highlight, as every row.
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: padding,
            alignment: alignment,
            child: child,
          ),
        ),
      ),
    );
  }

  /// The card's outline: the card corner, an edge with Increase Contrast,
  /// or the 2 pt primary edge when [selected].
  static RoundedRectangleBorder shape(
    BuildContext context, {
    bool selected = false,
  }) => RoundedRectangleBorder(
    borderRadius: YiviCorners.cardRadius,
    side: selected
        ? BorderSide(width: 2, color: YiviPalette.of(context).primary)
        : YiviEdges.block(context),
  );

  /// The look of a [SurfaceCard], for a box that draws its own: the surface
  /// colour in the card corner, outlined with Increase Contrast.
  static ShapeDecoration decoration(
    BuildContext context, {
    bool selected = false,
  }) => ShapeDecoration(
    color: YiviPalette.of(context).surface,
    shape: shape(context, selected: selected),
  );
}
