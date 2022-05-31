import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

class IrmaOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onPressedDisabled;
  final TextStyle? textStyle;
  final IrmaButtonSize? size;
  final IconData? icon;
  final double minWidth;

  const IrmaOutlinedButton({
    required this.label,
    this.onPressed,
    this.onPressedDisabled,
    this.textStyle,
    this.minWidth = 232,
    this.size,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaThemedButton(
      label: label,
      onPressed: onPressed,
      onPressedDisabled: onPressedDisabled,
      textStyle: textStyle,
      minWidth: minWidth,
      size: size,
      icon: icon,
      color: Colors.transparent,
      disabledColor: Colors.white,
      textColor: IrmaTheme.of(context).primaryBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
        side: BorderSide(
          color: onPressed != null ? IrmaTheme.of(context).primaryBlue : IrmaTheme.of(context).disabled,
          width: 2,
        ),
      ),
    );
  }
}
