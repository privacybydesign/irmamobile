import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'irma_themed_button.dart';

class IrmaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onPressedDisabled;
  final TextStyle? textStyle;
  final IrmaButtonSize? size;
  final double minWidth;
  final IconData? icon;
  final Color? color;
  final bool isSecondary;

  const IrmaButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.onPressedDisabled,
    this.textStyle,
    this.size,
    this.minWidth = 232,
    this.icon,
    this.color,
    this.isSecondary = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaThemedButton(
      label: label,
      onPressed: onPressed,
      onPressedDisabled: onPressedDisabled,
      textStyle: textStyle,
      size: size,
      minWidth: minWidth,
      icon: icon,
      color: color ?? theme.themeData.colorScheme.secondary,
      disabledColor: color ?? theme.themeData.colorScheme.secondary.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
      isSecondary: isSecondary,
    );
  }
}
