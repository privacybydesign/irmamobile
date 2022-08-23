import 'package:flutter/material.dart';

import '../theme/theme.dart';

class IrmaIconButton extends StatelessWidget {
  final IconData icon;
  final Function() onTap;

  const IrmaIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        right: theme.defaultSpacing,
        top: theme.defaultSpacing,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: CircleAvatar(
          backgroundColor: theme.neutralExtraLight,
          radius: 18,
          child: Icon(
            icon,
            size: 20,
            color: theme.neutral,
          ),
        ),
      ),
    );
  }
}
