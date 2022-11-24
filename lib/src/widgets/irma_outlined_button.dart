import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'irma_themed_button.dart';

class IrmaOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final TextStyle? textStyle;
  final IrmaButtonSize? size;
  final IconData? icon;
  final double minWidth;

  const IrmaOutlinedButton({
    required this.label,
    this.onPressed,
    this.textStyle,
    this.minWidth = 232,
    this.size,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return IrmaThemedButton(
      label: label,
      onPressed: onPressed,
      textStyle: textStyle,
      minWidth: minWidth,
      size: size,
      icon: icon,
      color: Colors.transparent,
      disabledColor: Colors.white,
      textColor: theme.themeData.colorScheme.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: onPressed != null ? theme.themeData.colorScheme.secondary : theme.themeData.disabledColor,
          width: 2,
        ),
      ),
    );
  }
}
