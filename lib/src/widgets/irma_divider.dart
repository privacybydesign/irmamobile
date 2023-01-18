import 'package:flutter/material.dart';

import '../theme/theme.dart';

class IrmaDivider extends StatelessWidget {
  final bool isDisabled;
  final Color? color;

  const IrmaDivider({
    this.isDisabled = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          color: color ?? (isDisabled ? theme.light : theme.neutralExtraLight),
        ),
      ),
    );
  }
}
