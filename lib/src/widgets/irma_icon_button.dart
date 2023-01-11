import 'package:flutter/material.dart';

import '../theme/theme.dart';

class IrmaIconButton extends StatelessWidget {
  final IconData icon;
  final Function() onTap;
  final double size;

  const IrmaIconButton({
    required this.icon,
    required this.onTap,
    this.size = 24,
  }) : assert(size >= 2);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final borderRadius = BorderRadius.circular(25.0);

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Icon(
          icon,
          size: size,
          color: theme.neutralExtraDark,
        ),
      ),
    );
  }
}
