import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "../theme/yivi_shadows.dart";

/// A white card around [child]: the surface colour, the card corner and the
/// card shadow ([YiviShadows.surfaceCard]). With [clipBehavior] the child
/// is clipped to the corners.
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
    decoration: YiviShadows.surfaceCard(YiviPalette.of(context)),
    child: child,
  );
}
