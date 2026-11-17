import "package:material_ui/material_ui.dart";

import "../theme/yivi_corners.dart";
import "../theme/yivi_edges.dart";
import "../theme/yivi_palette.dart";
import "../theme/yivi_space.dart";

enum IrmaCardStyle { normal, highlighted, danger }

/// Variant of Material's Card that uses IRMA styling: a rounded group on the
/// surface colour, flat, as in the glass redesign.
class IrmaCard extends StatelessWidget {
  final Function()? onTap;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final IrmaCardStyle style;
  final EdgeInsetsGeometry? margin;

  const IrmaCard({
    super.key,
    this.onTap,
    this.child,
    this.padding,
    this.style = IrmaCardStyle.normal,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    // By brightness only: the card keeps its colours on a sheet too.
    final palette = YiviPalette.forBrightness(Theme.of(context).brightness);
    const radius = YiviCorners.cardRadius;

    final BoxDecoration boxDecoration;
    switch (style) {
      case IrmaCardStyle.normal:
        boxDecoration = BoxDecoration(
          borderRadius: radius,
          border: Border.fromBorderSide(YiviEdges.block(context)),
          color: palette.surface,
        );
        break;
      case IrmaCardStyle.highlighted:
        boxDecoration = BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: palette.outline, width: 1),
          color: palette.tint,
        );
        break;
      case IrmaCardStyle.danger:
        boxDecoration = BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: palette.errorOutline, width: 1),
          color: palette.errorSurface,
        );
        break;
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Container(
        decoration: boxDecoration,
        child: ClipRRect(
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Container(
              // In this context the "margin" is set on the container padding.
              padding: margin ?? const EdgeInsets.all(YiviSpace.x16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
