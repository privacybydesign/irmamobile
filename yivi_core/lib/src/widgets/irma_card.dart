import "package:flutter/material.dart";

import "../theme/theme.dart";

enum IrmaCardStyle { normal, outlined, highlighted, danger }

/// Variant of Material's Card that uses IRMA styling.
class IrmaCard extends StatelessWidget {
  final Function()? onTap;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final IrmaCardStyle style;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool hasShadow;

  const IrmaCard({
    super.key,
    this.onTap,
    this.child,
    this.padding,
    this.style = IrmaCardStyle.normal,
    this.margin,
    this.color,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    BoxDecoration boxDecoration;
    switch (style) {
      case IrmaCardStyle.normal:
        boxDecoration = BoxDecoration(
          borderRadius: context.yivi.borderRadius,
          border: Border.all(width: 0, color: Colors.transparent),
          color: Colors.white,
        );
        break;
      case IrmaCardStyle.outlined:
        boxDecoration = BoxDecoration(
          borderRadius: context.yivi.borderRadius,
          border: Border.all(color: context.colors.secondary, width: 1),
          color: Colors.white,
        );
        break;
      case IrmaCardStyle.highlighted:
        boxDecoration = BoxDecoration(
          borderRadius: context.yivi.borderRadius,
          border: Border.all(color: context.colors.tertiary, width: 1),
          color: context.colors.surfaceContainerHigh,
        );
        break;
      case IrmaCardStyle.danger:
        boxDecoration = BoxDecoration(
          borderRadius: context.yivi.borderRadius,
          border: Border.all(color: context.yivi.brand.danger, width: 1),
          color: context.colors.surfaceContainerHighest,
        );
        break;
    }

    // Override card color if a color is provided
    if (color != null) {
      boxDecoration = boxDecoration.copyWith(color: color);
    }

    if (hasShadow) {
      boxDecoration = boxDecoration.copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0.0, 1.0),
            blurRadius: 6.0,
          ),
        ],
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Container(
        decoration: boxDecoration,
        child: ClipRRect(
          borderRadius: context.yivi.borderRadius,
          child: InkWell(
            borderRadius: context.yivi.borderRadius,
            onTap: onTap,
            child: Container(
              // In this context the "margin" is set on the container padding.
              padding: margin ?? EdgeInsets.all(context.yivi.defaultSpacing),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
