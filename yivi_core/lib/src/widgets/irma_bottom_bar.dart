import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "irma_bottom_bar_base.dart";
import "yivi_themed_button.dart";

export "irma_bottom_bar_base.dart" show IrmaBottomBarStyle;

enum IrmaBottomBarAlignment { horizontal, vertical, automatic }

class IrmaBottomBar extends StatelessWidget {
  final String? primaryButtonLabel;
  final Widget? primaryButtonLeading;
  final VoidCallback? onPrimaryPressed;
  final bool showTooltipOnPrimary;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryPressed;
  final IrmaBottomBarAlignment alignment;
  final IrmaBottomBarStyle style;

  const IrmaBottomBar({
    super.key,
    this.primaryButtonLabel,
    this.primaryButtonLeading,
    this.onPrimaryPressed,
    this.showTooltipOnPrimary = false,
    this.secondaryButtonLabel,
    this.onSecondaryPressed,
    this.alignment = IrmaBottomBarAlignment.automatic,
    this.style = IrmaBottomBarStyle.standard,
  });

  bool get _flat => style == IrmaBottomBarStyle.flat;

  YiviButtonSize get _buttonSize =>
      _flat ? YiviButtonSize.slim : YiviButtonSize.medium;

  Widget _buildPrimaryButton(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: _flat ? 0 : IrmaTheme.of(context).tinySpacing,
        ),
        child: YiviThemedButton(
          key: const Key("bottom_bar_primary"),
          onPressed: onPrimaryPressed,
          label: primaryButtonLabel!,
          leading: primaryButtonLeading,
          size: _buttonSize,
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return Expanded(
      child: YiviThemedButton(
        key: const Key("bottom_bar_secondary"),
        onPressed: onSecondaryPressed,
        label: secondaryButtonLabel!,
        style: YiviButtonStyle.outlined,
        size: _buttonSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return IrmaBottomBarBase(
      style: style,
      // Change layout according to limited height (i.e. landscape mode) and alignment setting.
      child:
          alignment == IrmaBottomBarAlignment.vertical ||
              alignment == IrmaBottomBarAlignment.automatic &&
                  mediaQuery.size.height > 450
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (primaryButtonLabel != null)
                  Row(children: [_buildPrimaryButton(context)]),
                if (secondaryButtonLabel != null) ...[
                  SizedBox(
                    height: _flat ? theme.smallSpacing : theme.tinySpacing,
                  ),
                  Row(children: [_buildSecondaryButton(context)]),
                ],
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (secondaryButtonLabel != null) ...[
                  _buildSecondaryButton(context),
                  SizedBox(width: theme.tinySpacing),
                ],
                if (primaryButtonLabel != null) _buildPrimaryButton(context),
              ],
            ),
    );
  }
}
