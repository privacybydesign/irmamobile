import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../theme/theme.dart';
import 'translated_text.dart';

enum CustomButtonStyle {
  fancy,
  outlined,
  filled,
}

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final CustomButtonStyle style;
  final CustomButtonSize size;

  const CustomButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.style = CustomButtonStyle.fancy,
    this.size = CustomButtonSize.medium,
  }) : super(key: key);

  Widget _buildFancyButton(Widget child) => Stack(
        children: [
          Positioned.fill(
            bottom: 0.0,
            child: SvgPicture.asset(
              'assets/ui/btn-bg.svg',
              alignment: Alignment.center,
              fit: BoxFit.fill,
            ),
          ),
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                child: child,
                onTap: onPressed,
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    const borderRadius = BorderRadius.all(
      Radius.circular(8),
    );

    final centeredTextWidget = Center(
      child: TranslatedText(
        label,
        style: theme.textTheme.button!.copyWith(
          color: style == CustomButtonStyle.outlined ? theme.neutralExtraDark : theme.light,
        ),
      ),
    );

    Widget buttonWidget = SizedBox(
      height: size.value,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: style == CustomButtonStyle.fancy
            ? _buildFancyButton(centeredTextWidget)
            : Material(
                child: InkWell(
                  onTap: onPressed,
                  child: Ink(
                    child: centeredTextWidget,
                    decoration: style == CustomButtonStyle.filled
                        // Filled button
                        ? BoxDecoration(
                            color: theme.neutralDark,
                            borderRadius: borderRadius,
                          )
                        // Outlined button
                        : BoxDecoration(
                            color: theme.light,
                            borderRadius: borderRadius,
                            border: Border.all(
                              width: 1.7,
                              style: BorderStyle.solid,
                              color: theme.neutralExtraDark,
                            ),
                          ),
                  ),
                ),
              ),
      ),
    );

    // Grey out button if it's disabled
    if (onPressed == null) {
      buttonWidget = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.white.withOpacity(0.5),
          BlendMode.modulate,
        ),
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }
}

class CustomButtonSize {
  final double _value;
  const CustomButtonSize._internal(this._value);
  double get value => _value;

  static const large = CustomButtonSize._internal(54);
  static const medium = CustomButtonSize._internal(50);
  static const small = CustomButtonSize._internal(55);
}
