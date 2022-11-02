import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';

class IrmaThemedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color? disabledColor;
  final Color? textColor;
  final OutlinedBorder shape;
  final IrmaButtonSize? size;
  final double minWidth;
  final TextStyle? textStyle;
  final IconData? icon;
  final bool isSecondary;

  const IrmaThemedButton({
    required this.label,
    required this.onPressed,
    required this.color,
    this.disabledColor,
    this.textColor,
    required this.shape,
    this.size,
    this.minWidth = 232,
    this.textStyle,
    this.icon,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      FlutterI18n.translate(context, label),
      style: textStyle ??
          IrmaTheme.of(context).textTheme.button!.copyWith(
                color: isSecondary ? color : Colors.white,
              ),
    );

    final fixedHeight = size != null ? size!.value : IrmaButtonSize.medium.value;

    final style = ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.disabled)) {
          return disabledColor;
        } else {
          return isSecondary ? Colors.white : color;
        }
      }),
      foregroundColor:
          MaterialStateProperty.resolveWith<Color?>((_) => textColor ?? (isSecondary ? color : Colors.white)),
      side: MaterialStateProperty.resolveWith<BorderSide?>((_) => isSecondary ? BorderSide(color: color) : null),
      shape: MaterialStateProperty.resolveWith<OutlinedBorder?>((_) => shape),
      padding: MaterialStateProperty.resolveWith<EdgeInsets>(
        (_) => const EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 20.0,
        ),
      ),
      minimumSize: MaterialStateProperty.resolveWith<Size>(
        (_) => Size(minWidth, fixedHeight),
      ),
      maximumSize: MaterialStateProperty.resolveWith<Size>(
        (_) => Size.fromHeight(fixedHeight),
      ),
    );

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: icon == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon),
                const SizedBox(
                  width: 10.0,
                ),
                text,
              ],
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
  static const extraSmall = IrmaButtonSize._internal(35);
}
