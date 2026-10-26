import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "../theme/yivi_corners.dart";
import "../theme/yivi_edges.dart";

enum IrmaCardStyle { normal, outlined, highlighted, danger }

/// Variant of Material's Card that uses IRMA styling: a rounded group on the
/// surface colour, flat, as in the glass redesign.
class IrmaCard extends StatelessWidget {
  final Function()? onTap;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final IrmaCardStyle style;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const IrmaCard({
    super.key,
    this.onTap,
    this.child,
    this.padding,
    this.style = IrmaCardStyle.normal,
    this.margin,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    const radius = YiviCorners.cardRadius;

    BoxDecoration boxDecoration;
    switch (style) {
      case IrmaCardStyle.normal:
        boxDecoration = BoxDecoration(
          borderRadius: radius,
          border: Border.fromBorderSide(YiviEdges.block(context)),
          color: theme.light,
        );
        break;
      case IrmaCardStyle.outlined:
        boxDecoration = BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: theme.themeData.colorScheme.secondary,
            width: 1,
          ),
          color: theme.light,
        );
        break;
      case IrmaCardStyle.highlighted:
        boxDecoration = BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: theme.tertiary, width: 1),
          color: theme.surfaceSecondary,
        );
        break;
      case IrmaCardStyle.danger:
        boxDecoration = BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: theme.danger, width: 1),
          color: theme.surfaceTertiary,
        );
        break;
    }

    // Override card color if a color is provided
    if (color != null) {
      boxDecoration = boxDecoration.copyWith(color: color);
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
              padding: margin ?? EdgeInsets.all(theme.defaultSpacing),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
