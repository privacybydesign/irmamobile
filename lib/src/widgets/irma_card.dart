import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Variant of Material's Card that uses IRMA styling.

enum IrmaCardStyle { normal, template, selected }

class IrmaCard extends StatelessWidget {
  final Function()? onTap;
  final Widget? child;

  final IrmaCardStyle style;

  const IrmaCard({
    Key? key,
    this.onTap,
    this.child,
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
      padding: EdgeInsets.all(theme.tinySpacing),
      child: Container(
        padding: EdgeInsets.all(theme.smallSpacing),
        decoration: style == IrmaCardStyle.template
            //Template styling
            ? DottedDecoration(
                shape: Shape.box,
                borderRadius: borderRadius,
                color: Colors.grey.shade300,
              )
            : style == IrmaCardStyle.selected
                //Selected styling
                ? BoxDecoration(
                    borderRadius: borderRadius,
                    border: Border.all(color: theme.themeData.primaryColor.withOpacity(0.8)),
                    color: theme.lightBlue,
                    boxShadow: shadow)
                //Normal styling
                : BoxDecoration(
                    borderRadius: borderRadius,
                    border: Border.all(color: Colors.transparent),
                    color: Colors.white,
                    boxShadow: shadow,
                  ),
        child: InkWell(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}
