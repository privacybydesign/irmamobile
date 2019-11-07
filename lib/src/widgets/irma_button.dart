import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

class IrmaButton extends StatelessWidget {
  final String label;
  final Function onPressed;
  final TextStyle textStyle;
  final IrmaButtonSize size;
  final IconData icon;

  IrmaButton({
    @required this.label,
    this.onPressed,
    this.textStyle,
    this.size,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaThemedButton(
      label: label,
      onPressed: onPressed,
      textStyle: textStyle,
      size: size,
      icon: icon,
      color: IrmaTheme.of(context).primaryBlue,
      disabledColor: IrmaTheme.of(context).disabled,
      textColor: IrmaTheme.of(context).grayscaleWhite,
      shape: RoundedRectangleBorder(
        borderRadius: new BorderRadius.circular(30.0),
      ),
    );
  }
}
