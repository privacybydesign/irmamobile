import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum IrmaCardStyle {
  normal,
  flat,
  outlined,
  highlighted,
  danger,
}

/// Variant of Material's Card that uses IRMA styling.
class IrmaCard extends StatelessWidget {
  final Function()? onTap;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final IrmaCardStyle style;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const IrmaCard({
    Key? key,
    this.onTap,
    this.child,
    this.padding,
    this.style = IrmaCardStyle.normal,
    this.margin,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final shadow = [
      BoxShadow(
        color: Colors.grey.shade300,
        offset: const Offset(0.0, 1.0),
        blurRadius: 6.0,
      )
    ];

    BoxDecoration boxDecoration;
    switch (style) {
      case IrmaCardStyle.normal:
        boxDecoration = BoxDecoration(
          borderRadius: theme.borderRadius,
          border: Border.all(color: Colors.transparent),
          boxShadow: shadow,
          color: theme.light,
        );
        break;
      case IrmaCardStyle.flat:
        boxDecoration = BoxDecoration(
          borderRadius: theme.borderRadius,
          border: Border.all(color: Colors.transparent),
          color: theme.light,
        );
        break;
      case IrmaCardStyle.outlined:
        boxDecoration = BoxDecoration(
          borderRadius: theme.borderRadius,
          border: Border.all(
            color: theme.themeData.colorScheme.secondary,
            width: 1,
          ),
          color: Colors.white,
          boxShadow: shadow,
        );
        break;
      case IrmaCardStyle.highlighted:
        boxDecoration = BoxDecoration(
          borderRadius: theme.borderRadius,
          border: Border.all(
            color: theme.tertiary,
            width: 1,
          ),
          color: theme.surfaceSecondary,
        );
        break;
      case IrmaCardStyle.danger:
        boxDecoration = BoxDecoration(
          borderRadius: theme.borderRadius,
          border: Border.all(
            color: theme.danger,
            width: 1,
          ),
          color: theme.surfaceTertiary,
          boxShadow: shadow,
        );
        break;
    }

    // Override card color if a color is provided
    if (color != null) {
      boxDecoration = boxDecoration.copyWith(color: color);
    }

    return Padding(
      padding: padding ?? EdgeInsets.all(theme.tinySpacing),
      child: InkWell(
        borderRadius: theme.borderRadius,
        onTap: onTap,
        child: Container(
          //In this context the "margin" is set on the container padding.
          padding: margin ?? EdgeInsets.all(theme.defaultSpacing),
          decoration: boxDecoration,
          child: child,
        ),
      ),
    );
  }
}
