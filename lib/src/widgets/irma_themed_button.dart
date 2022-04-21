import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';

class IrmaThemedButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final VoidCallback? onPressedDisabled;
  final Color color;
  final Color? disabledColor;
  final Color? textColor;
  final OutlinedBorder shape;
  final IrmaButtonSize? size;
  final double minWidth;
  final TextStyle? textStyle;
  final IconData? icon;
  final bool isSecondary;

  const IrmaThemedButton(
      {this.label,
      required this.onPressed,
      this.onPressedDisabled,
      required this.color,
      this.disabledColor,
      this.textColor,
      required this.shape,
      this.size,
      this.minWidth = 232,
      this.textStyle,
      this.icon,
      this.isSecondary = false});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      FlutterI18n.translate(context, label ?? ''),
      style: textStyle ?? IrmaTheme.of(context).textTheme.button,
    );

    final fixedHeight = size != null ? size!.value : IrmaButtonSize.medium.value;

    return GestureDetector(
      excludeFromSemantics: true,
      onTapUp: (_) => onPressed == null ? onPressedDisabled?.call() : onPressed!(),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          side: isSecondary ? BorderSide(color: color) : null,
          elevation: 0.0,
          primary: isSecondary ? Colors.white : color,
          onPrimary: textColor ?? (isSecondary ? color : Colors.white),
          onSurface: disabledColor ?? IrmaTheme.of(context).disabled,
          shape: shape,
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
          minimumSize: Size(minWidth, fixedHeight),
          maximumSize: Size.fromHeight(fixedHeight),
        ),
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
