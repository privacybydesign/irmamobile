// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';

class IrmaThemedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final VoidCallback onPressedDisabled;
  final Color color;
  final Color disabledColor;
  final Color textColor;
  final ShapeBorder shape;
  final IrmaButtonSize size;
  final double minWidth;
  final TextStyle textStyle;
  final IconData icon;

  const IrmaThemedButton({
    @required this.label,
    @required this.onPressed,
    this.onPressedDisabled,
    @required this.color,
    this.disabledColor,
    @required this.textColor,
    @required this.shape,
    this.size,
    this.minWidth = 232,
    this.textStyle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      FlutterI18n.translate(context, label),
      style: textStyle,
    );

    return GestureDetector(
      excludeFromSemantics: true,
      onTapUp: (_) {
        if (onPressed == null && onPressedDisabled != null) {
          onPressedDisabled();
        }
      },
      child: ButtonTheme(
        textTheme: ButtonTextTheme.primary,
        height: size?.value ?? IrmaButtonSize.medium.value,
        minWidth: minWidth,
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        child: RaisedButton(
          onPressed: onPressed,
          elevation: 0.0,
          color: color,
          disabledColor: disabledColor ?? IrmaTheme.of(context).disabled,
          textColor: textColor,
          shape: shape,
          child: icon == null
              ? text
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(icon),
                    const SizedBox(
                      width: 10.0,
                    ),
                    text,
                  ],
                ),
        ),
      ),
    );
  }
}

class IrmaButtonSize {
  final double _value;
  const IrmaButtonSize._internal(this._value);
  double get value => _value;

  static const large = IrmaButtonSize._internal(54);
  static const medium = IrmaButtonSize._internal(48);
  static const small = IrmaButtonSize._internal(40);
}
