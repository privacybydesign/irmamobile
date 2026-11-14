import "package:material_ui/material_ui.dart";

import "../theme/yivi_space.dart";
import "../util/i18n.dart";
import "glass/pill_buttons.dart";
import "irma_bottom_bar_base.dart";

class IrmaBottomBar extends StatelessWidget {
  final String? primaryButtonLabel;
  final VoidCallback? onPrimaryPressed;

  /// The primary is a red pill, for an action that deletes data.
  final bool primaryDanger;
  final String? secondaryButtonLabel;

  /// The values for the placeholders in [secondaryButtonLabel].
  final Map<String, String>? secondaryButtonParams;
  final VoidCallback? onSecondaryPressed;

  const IrmaBottomBar({
    super.key,
    this.primaryButtonLabel,
    this.onPrimaryPressed,
    this.primaryDanger = false,
    this.secondaryButtonLabel,
    this.secondaryButtonParams,
    this.onSecondaryPressed,
  });

  Widget _buildPrimaryButton(BuildContext context) {
    return Expanded(
      child: Padding(
        // Nothing under it, so a bar of one button ends where every bar does.
        padding: const EdgeInsets.only(top: YiviSpace.x4),
        child: primaryDanger
            ? PillButton(
                key: const Key("bottom_bar_primary"),
                onPressed: onPrimaryPressed,
                label: context.tr(primaryButtonLabel!),
                style: PillStyle.dangerFilled,
                size: PillSize.large,
              )
            : FancyPillButton(
                key: const Key("bottom_bar_primary"),
                label: context.tr(primaryButtonLabel!),
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
        label: context.tr(secondaryButtonLabel!, secondaryButtonParams),
        style: PillStyle.text,
        size: PillSize.large,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Change layout according to limited height (i.e. landscape mode).
    final vertical = MediaQuery.sizeOf(context).height > 450;
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
                  const SizedBox(height: YiviSpace.x8),
                  Row(children: [_buildSecondaryButton(context)]),
                ],
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (secondaryButtonLabel != null) ...[
                  _buildSecondaryButton(context),
                  const SizedBox(width: YiviSpace.x4),
                ],
                if (primaryButtonLabel != null) _buildPrimaryButton(context),
              ],
            ),
    );
  }
}
