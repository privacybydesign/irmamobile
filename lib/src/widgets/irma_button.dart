import 'package:flutter/material.dart';

import 'irma_themed_button.dart';

class IrmaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
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
    this.textStyle,
    this.size,
    this.minWidth = 232,
    this.icon,
    this.color,
    this.isSecondary = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IrmaThemedButton(
      label: label,
      onPressed: onPressed,
      textStyle: textStyle,
      size: size,
      minWidth: minWidth,
      icon: icon,
      color: color,
      isSecondary: isSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}
