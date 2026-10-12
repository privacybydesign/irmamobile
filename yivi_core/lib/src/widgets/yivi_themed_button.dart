import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";

import "../../package_name.dart";
import "../theme/theme.dart";
import "../widgets/link.dart";
import "slim_button_background.dart";
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

// Space between the leading widget of a button and its label.
const _leadingGap = 10.0;

class YiviButtonSize {
  final double _value;
  final double outlineWidth;
  const YiviButtonSize._internal(this._value, {this.outlineWidth = 1.7});
  double get value => _value;

  static const large = YiviButtonSize._internal(55);
  static const medium = YiviButtonSize._internal(50);
  static const small = YiviButtonSize._internal(37);

  /// The button of the e-mail linking screens (`FeatureFlag.emailLinking`).
  static const slim = YiviButtonSize._internal(48, outlineWidth: 1);
}

class YiviThemedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final YiviButtonStyle style;
  final YiviButtonSize size;
  final bool isTransparent;

  /// Shown before the label, as the progress indicator of a busy button.
  final Widget? leading;

  const YiviThemedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = YiviButtonStyle.fancy,
    this.size = YiviButtonSize.medium,
    this.isTransparent = false,
    this.leading,
  }) : assert(
         !isTransparent || style != YiviButtonStyle.fancy,
         "Fancy button cannot be transparent",
       );

  Widget _buildFancyButton(Widget child) => Stack(
    children: [
      Positioned.fill(
        bottom: 0.0,
        child: ExcludeSemantics(
          child: size == YiviButtonSize.slim
              ? const SlimButtonBackground()
              : SvgPicture.asset(
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
    IrmaThemeData theme,
    BorderRadiusGeometry borderRadius,
  ) {
    return Material(
      color: isTransparent ? Colors.transparent : theme.light,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
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
                    width: size.outlineWidth,
                    style: BorderStyle.solid,
                    color: theme.neutralExtraDark,
                  ),
                ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    const borderRadius = BorderRadius.all(Radius.circular(8));

    double buttonHeight = size.value;
    double? buttonWidth;
    if (size == YiviButtonSize.small) {
      buttonWidth = size.value * 4;
    }

    TextStyle baseTextStyle = theme.textTheme.labelLarge!;
    if (size == YiviButtonSize.small) {
      baseTextStyle = baseTextStyle.copyWith(
        fontFamily: theme.secondaryFontFamily,
        fontSize: 14,
      );
    }

    final labelWidget = TranslatedText(
      label,
      textAlign: TextAlign.center,
      style: baseTextStyle.copyWith(
        color: style == YiviButtonStyle.outlined
            ? theme.neutralExtraDark
            : theme.light,
      ),
    );
    final centeredTextWidget = Center(
      child: leading == null
          ? labelWidget
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                leading!,
                const SizedBox(width: _leadingGap),
                Flexible(child: labelWidget),
              ],
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
              : _buildNormalButton(centeredTextWidget, theme, borderRadius),
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
