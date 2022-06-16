import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum IrmaCardStyle {
  normal,
  outlined,
  highlighted,
  template,
}

/// Variant of Material's Card that uses IRMA styling.
class IrmaCard extends StatelessWidget {
  final Function()? onTap;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final IrmaCardStyle style;

  const IrmaCard({
    Key? key,
    this.onTap,
    this.child,
    this.padding,
    this.style = IrmaCardStyle.normal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final borderRadius = BorderRadius.circular(15.0);
    final shadow = [
      BoxShadow(
        color: Colors.grey.shade300,
        offset: const Offset(0.0, 1.0),
        blurRadius: 6.0,
      )
    ];

    return Padding(
      padding: padding ?? EdgeInsets.all(theme.tinySpacing),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(theme.smallSpacing),
          decoration: style == IrmaCardStyle.template
              //Template styling
              ? DottedDecoration(
                  shape: Shape.box,
                  borderRadius: borderRadius,
                  color: Colors.grey.shade300,
                )
              : style == IrmaCardStyle.highlighted || style == IrmaCardStyle.outlined
                  //Selected styling
                  ? BoxDecoration(
                      borderRadius: borderRadius,
                      border: Border.all(
                        color: theme.themeData.primaryColor,
                        width: 2,
                      ),
                      color: style == IrmaCardStyle.highlighted ? theme.lightBlue : Colors.white,
                      boxShadow: shadow)
                  //Normal styling
                  : BoxDecoration(
                      borderRadius: borderRadius,
                      border: Border.all(color: Colors.transparent),
                      color: Colors.white,
                      boxShadow: shadow,
                    ),
          child: child,
        ),
      ),
    );
  }
}
