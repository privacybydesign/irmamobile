import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../theme/theme.dart';
import 'translated_text.dart';

enum YiviButtonStyle {
  fancy,
  outlined,
  filled,
}

class YiviButtonSize {
  final double _value;
  const YiviButtonSize._internal(this._value);
  double get value => _value;

  static const large = YiviButtonSize._internal(55);
  static const medium = YiviButtonSize._internal(50);
  static const small = YiviButtonSize._internal(45);
}

class YiviThemedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final YiviButtonStyle style;
  final YiviButtonSize size;

  const YiviThemedButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.style = YiviButtonStyle.fancy,
    this.size = YiviButtonSize.medium,
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

  Widget _buildNormalButton(
    Widget child,
    IrmaThemeData theme,
    BorderRadiusGeometry borderRadius,
  ) {
    return Material(
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          child: child,
          decoration: style == YiviButtonStyle.filled
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
    );
  }

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
          color: style == YiviButtonStyle.outlined ? theme.neutralExtraDark : theme.light,
        ),
      ),
    );

    Widget buttonWidget = SizedBox(
      height: size.value,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: style == YiviButtonStyle.fancy
            ? _buildFancyButton(centeredTextWidget)
            : _buildNormalButton(
                centeredTextWidget,
                theme,
                borderRadius,
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
