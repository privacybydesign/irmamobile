import 'package:flutter/material.dart';

import '../theme/theme.dart';

class ActiveIndicator extends StatelessWidget {
  final bool isActive;

  const ActiveIndicator(this.isActive);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final color = isActive ? theme.success : theme.primary;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
