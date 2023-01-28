import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum IrmaCardStyle {
  normal,
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

  const IrmaCard({
    Key? key,
    this.onTap,
    this.child,
    this.padding,
    this.style = IrmaCardStyle.normal,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final borderRadius = BorderRadius.circular(8);
    final shadow = [
      BoxShadow(
        color: Colors.grey.shade300,
        offset: const Offset(0.0, 1.0),
        blurRadius: 6.0,
      )
    ];

    final Decoration boxDecoration;
    switch (style) {
      case IrmaCardStyle.normal:
        boxDecoration = BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: Colors.transparent),
          boxShadow: shadow,
          color: theme.light,
        );
        break;
      case IrmaCardStyle.outlined:
        boxDecoration = BoxDecoration(
          borderRadius: borderRadius,
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
          borderRadius: borderRadius,
          border: Border.all(
            color: theme.themeData.colorScheme.secondary,
            width: 1,
          ),
          color: theme.surfaceSecondary,
          boxShadow: shadow,
        );
        break;
      case IrmaCardStyle.danger:
        boxDecoration = BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: theme.danger,
            width: 1,
          ),
          color: theme.surfaceTertiary,
          boxShadow: shadow,
        );
        break;
    }

    return Padding(
      padding: padding ?? EdgeInsets.all(theme.tinySpacing),
      child: InkWell(
        borderRadius: borderRadius,
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
