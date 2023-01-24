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
  static const small = YiviButtonSize._internal(37);
}

class YiviThemedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final YiviButtonStyle style;
  final YiviButtonSize size;
  final bool isTransparent;

  const YiviThemedButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.style = YiviButtonStyle.fancy,
    this.size = YiviButtonSize.medium,
    this.isTransparent = false,
  })  : assert(
          isTransparent != true || style != YiviButtonStyle.fancy,
          'Fancy button cannot be transparent',
        ),
        super(key: key);

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
      color: isTransparent ? Colors.transparent : theme.light,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          child: child,
          decoration: style == YiviButtonStyle.filled
              // Filled button
              ? BoxDecoration(
                  color: isTransparent ? null : theme.secondary,
                  borderRadius: borderRadius,
                )
              // Outlined button
              : BoxDecoration(
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

    double buttonHeight = size.value;
    double? buttonWidth;
    if (size == YiviButtonSize.small) {
      buttonWidth = size.value * 4;
    }

    TextStyle baseTextStyle = theme.textTheme.button!;
    if (size == YiviButtonSize.small) {
      baseTextStyle = baseTextStyle.copyWith(
        fontFamily: theme.secondaryFontFamily,
        fontSize: 14,
      );
    }

    final centeredTextWidget = Center(
      child: TranslatedText(
        label,
        textAlign: TextAlign.center,
        style: baseTextStyle.copyWith(
          color: style == YiviButtonStyle.outlined ? theme.neutralExtraDark : theme.light,
        ),
      ),
    );

    Widget buttonWidget = SizedBox(
      height: buttonHeight,
      width: buttonWidth,
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
