import 'package:flutter/material.dart';

import '../theme/theme.dart';

class IrmaIconButton extends StatelessWidget {
  final IconData icon;
  final Function() onTap;
  final double size;

  const IrmaIconButton({
    required this.icon,
    required this.onTap,
    this.size = 20,
  }) : assert(size >= 2);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: theme.neutralExtraLight,
        radius: size - 2,
        child: Icon(
          icon,
          size: size,
          color: theme.neutral,
        ),
      ),
    );
  }
}
