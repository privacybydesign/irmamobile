import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class NotificationIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final color = theme.primary;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
