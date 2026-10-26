import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "glass/pill_buttons.dart";
import "irma_bottom_bar_base.dart";

enum IrmaBottomBarAlignment { horizontal, automatic }

class IrmaBottomBar extends StatelessWidget {
  final String? primaryButtonLabel;
  final VoidCallback? onPrimaryPressed;

  /// The primary is a red pill, for an action that deletes data.
  final bool primaryDanger;
  final String? secondaryButtonLabel;

  /// The values for the placeholders in [secondaryButtonLabel].
  final Map<String, String>? secondaryButtonParams;
  final VoidCallback? onSecondaryPressed;
  final IrmaBottomBarAlignment alignment;

  const IrmaBottomBar({
    super.key,
    this.primaryButtonLabel,
    this.onPrimaryPressed,
    this.primaryDanger = false,
    this.secondaryButtonLabel,
    this.secondaryButtonParams,
    this.onSecondaryPressed,
    this.alignment = IrmaBottomBarAlignment.automatic,
  });

  Widget _buildPrimaryButton(BuildContext context) {
    return Expanded(
      child: Padding(
        // Nothing under it, so a bar of one button ends where every bar does.
        padding: EdgeInsets.only(top: IrmaTheme.of(context).tinySpacing),
        child: primaryDanger
            ? PillButton(
                key: const Key("bottom_bar_primary"),
                onPressed: onPrimaryPressed,
                label: FlutterI18n.translate(context, primaryButtonLabel!),
                style: PillStyle.dangerFilled,
                size: PillSize.large,
              )
            : FancyPillButton(
                key: const Key("bottom_bar_primary"),
                label: FlutterI18n.translate(context, primaryButtonLabel!),
                onPressed: onPrimaryPressed,
              ),
      ),
    );
  }

  // A plain text pill, as every secondary action in the redesign.
  Widget _buildSecondaryButton(BuildContext context) {
    return Expanded(
      child: PillButton(
        key: const Key("bottom_bar_secondary"),
        onPressed: onSecondaryPressed,
        label: FlutterI18n.translate(
          context,
          secondaryButtonLabel!,
          translationParams: secondaryButtonParams,
        ),
        style: PillStyle.text,
        size: PillSize.large,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final mediaQuery = MediaQuery.of(context);

    // Change layout according to limited height (i.e. landscape mode) and alignment setting.
    final vertical =
        alignment == IrmaBottomBarAlignment.automatic &&
        mediaQuery.size.height > 450;
    return IrmaBottomBarBase(
      // "Cancel" under the main button sits low, as on iOS.
      endsWithTextButton: vertical && secondaryButtonLabel != null,
      child: vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (primaryButtonLabel != null)
                  Row(children: [_buildPrimaryButton(context)]),
                if (secondaryButtonLabel != null) ...[
                  SizedBox(height: theme.smallSpacing),
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
