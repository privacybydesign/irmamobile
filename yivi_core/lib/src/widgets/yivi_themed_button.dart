import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/svg.dart";

import "../../package_name.dart";
import "../theme/theme.dart";
import "../widgets/link.dart";
import "translated_text.dart";

enum YiviButtonStyle { fancy, outlined, filled }

class YiviLinkButton extends StatelessWidget {
  const YiviLinkButton({
    super.key,
    required this.labelTranslationKey,
    required this.onTap,
    this.textAlign,
  });

  final TextAlign? textAlign;
  final String labelTranslationKey;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Link(
      textAlign: textAlign,
      onTap: onTap,
      label: FlutterI18n.translate(context, labelTranslationKey),
    );
  }
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
    super.key,
    required this.label,
    this.onPressed,
    this.style = YiviButtonStyle.fancy,
    this.size = YiviButtonSize.medium,
    this.isTransparent = false,
  }) : assert(
         !isTransparent || style != YiviButtonStyle.fancy,
         "Fancy button cannot be transparent",
       );

  Widget _buildFancyButton(Widget child) => Stack(
    children: [
      Positioned.fill(
        bottom: 0.0,
        child: ExcludeSemantics(
          child: SvgPicture.asset(
            yiviAsset("ui/btn-bg.svg"),
            alignment: Alignment.center,
            fit: BoxFit.fill,
          ),
        ),
      ),
      Positioned.fill(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(onTap: onPressed, child: child),
        ),
      ),
    ],
  );

  Widget _buildNormalButton(
    Widget child,
    BuildContext context,
    BorderRadiusGeometry borderRadius,
  ) {
    return Material(
      color: isTransparent ? Colors.transparent : Colors.white,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: style == YiviButtonStyle.filled
              // Filled button
              ? BoxDecoration(
                  color: isTransparent ? null : context.colors.secondary,
                  borderRadius: borderRadius,
                )
              // Outlined button
              : BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    width: 1.7,
                    style: BorderStyle.solid,
                    color: context.colors.onSurface,
                  ),
                ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(8));

    double buttonHeight = size.value;
    double? buttonWidth;
    if (size == YiviButtonSize.small) {
      buttonWidth = size.value * 4;
    }

    final textColor = style == YiviButtonStyle.outlined
        ? context.colors.onSurface
        : Colors.white;
    final labelStyle = size == YiviButtonSize.small
        ? context.text.labelMedium?.copyWith(color: textColor)
        : context.text.labelLarge?.copyWith(color: textColor);

    final centeredTextWidget = Center(
      child: TranslatedText(
        label,
        textAlign: TextAlign.center,
        style: labelStyle,
      ),
    );

    Widget buttonWidget = Semantics(
      button: true,
      child: SizedBox(
        height: buttonHeight,
        width: buttonWidth,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: style == YiviButtonStyle.fancy
              ? _buildFancyButton(centeredTextWidget)
              : _buildNormalButton(centeredTextWidget, context, borderRadius),
        ),
      ),
    );

    // Grey out button if it's disabled
    if (onPressed == null) {
      buttonWidget = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.white.withAlpha(128),
          BlendMode.modulate,
        ),
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }
}
