import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Variant of Material's Card that uses IRMA styling.
class IrmaCard extends StatelessWidget {
  final Function()? onTap;
  final Widget? child;
  final bool dottedBorder;

  const IrmaCard({Key? key, this.onTap, this.child, this.dottedBorder = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final borderRadius = BorderRadius.circular(15.0);

    return Container(
      padding: EdgeInsets.all(theme.smallSpacing),
      decoration: dottedBorder == true
          ? DottedDecoration(shape: Shape.box, borderRadius: borderRadius, color: Colors.grey.shade400)
          : BoxDecoration(borderRadius: borderRadius, color: Colors.white, boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                offset: const Offset(0.0, 1.0),
                blurRadius: 6.0,
              ),
            ]),
      child: InkWell(
        onTap: onTap,
        child: child,
      ),
    );
  }
}
