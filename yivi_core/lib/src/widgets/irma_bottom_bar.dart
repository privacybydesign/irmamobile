import "package:material_ui/material_ui.dart";

import "../util/i18n.dart";
import "action_bar.dart";

/// An [ActionBar] that translates its labels itself, for the screens that
/// are still to be replaced. New code uses [ActionBar].
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

  @override
  Widget build(BuildContext context) => ActionBar(
    actions: [
      if (primaryButtonLabel case final label?)
        ActionBar.primary(
          label: context.tr(label),
          onTap: onPrimaryPressed,
          danger: primaryDanger,
        ),
      if (secondaryButtonLabel case final label?)
        ActionBar.secondary(
          label: context.tr(label, secondaryButtonParams),
          onTap: onSecondaryPressed,
        ),
    ],
  );
}
