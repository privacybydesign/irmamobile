import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class IrmaThemedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color disabledColor;
  final Color textColor;
  final ShapeBorder shape;
  final IrmaButtonSize size;
  final TextStyle textStyle;
  final IconData icon;
  final double minWidth;

  const IrmaThemedButton({
    @required this.label,
    @required this.onPressed,
    @required this.color,
    @required this.disabledColor,
    @required this.textColor,
    @required this.shape,
    this.size,
    this.textStyle,
    this.icon,
    this.minWidth = 232.0,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      FlutterI18n.translate(context, label),
      style: textStyle,
    );
    return ButtonTheme(
      textTheme: ButtonTextTheme.primary,
      height: size?.value ?? IrmaButtonSize.medium.value,
      minWidth: minWidth,
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: RaisedButton(
        onPressed: onPressed,
        elevation: 0.0,
        color: color,
        disabledColor: disabledColor,
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
