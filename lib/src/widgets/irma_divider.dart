import 'package:flutter/material.dart';

import '../theme/theme.dart';

class IrmaDivider extends StatelessWidget {
  final Color? color;
  final EdgeInsets? padding;
  final bool vertical;
  final double? height;

  const IrmaDivider({
    this.color,
    this.padding,
    this.height,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Container(
        height: vertical ? height : 1,
        width: vertical ? 1 : null,
        color: color ?? theme.neutralExtraLight,
      ),
    );
  }
}
