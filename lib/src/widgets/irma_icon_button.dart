import 'package:flutter/material.dart';

import '../theme/theme.dart';

class IrmaIconButton extends StatelessWidget {
  final IconData icon;
  final Function() onTap;
  final double size;
  final EdgeInsets? padding;

  const IrmaIconButton({
    Key? key,
    required this.icon,
    required this.onTap,
    this.size = 24,
    this.padding,
  })  : assert(size >= 2),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final borderRadius = BorderRadius.circular(25.0);

    return Padding(
      padding: padding ?? const EdgeInsets.all(12),
      child: Material(
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
      ),
    );
  }
}
