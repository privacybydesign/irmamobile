import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';

class IrmaThemedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final OutlinedBorder shape;
  final IrmaButtonSize? size;
  final double minWidth;
  final TextStyle? textStyle;
  final IconData? icon;
  final bool isSecondary;

  const IrmaThemedButton({
    required this.label,
    required this.onPressed,
    required this.shape,
    this.color,
    this.size,
    this.minWidth = 232,
    this.textStyle,
    this.icon,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final Color baseColor = color ?? theme.themeData.colorScheme.secondary;

    final Color textColor;
    final Color backgroundColor;
    Color? borderColor;

    if (!isSecondary) {
      if (onPressed != null) {
        // Primary button colors
        textColor = theme.light;
        backgroundColor = baseColor;
      } else {
        // Disabled Primary button colors
        textColor = theme.light;
        backgroundColor = baseColor.withAlpha(128);
      }
    } else {
      if (onPressed != null) {
        //  Secondary button colors
        textColor = baseColor;
        backgroundColor = theme.light;
        borderColor = baseColor;
      } else {
        //  Disabled Secondary button colors
        textColor = theme.light;
        backgroundColor = theme.neutralLight;
      }
    }

    final textWidget = Text(
      FlutterI18n.translate(context, label),
      style: textStyle ?? IrmaTheme.of(context).textTheme.labelLarge!.copyWith(color: textColor),
    );

    final fixedHeight = size != null ? size!.value : IrmaButtonSize.medium.value;

    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((_) => backgroundColor),
      side: borderColor != null
          ? WidgetStateProperty.resolveWith<BorderSide?>((_) => BorderSide(color: borderColor!))
          : null,
      shape: WidgetStateProperty.resolveWith<OutlinedBorder?>((_) => shape),
      padding: WidgetStateProperty.resolveWith<EdgeInsets>(
        (_) => const EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 20.0,
        ),
      ),
      minimumSize: WidgetStateProperty.resolveWith<Size>(
        (_) => Size(minWidth, fixedHeight),
      ),
      maximumSize: WidgetStateProperty.resolveWith<Size>(
        (_) => Size.fromHeight(fixedHeight),
      ),
    );

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: icon == null
          ? textWidget
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon),
                const SizedBox(
                  width: 10.0,
                ),
                textWidget,
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
