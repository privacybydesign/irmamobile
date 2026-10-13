import "dart:math";

import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "missing_data_button.dart";

const _minBottomPadding = 32.0;

/// The bottom of the missing data screens: a white block with a soft shadow
/// above it, holding [children] one under the other.
class MissingDataBottomBar extends StatelessWidget {
  final List<Widget> children;

  const MissingDataBottomBar({super.key, required this.children});

  /// A primary and a secondary button, as the issuance screens have in
  /// [IrmaBottomBar].
  MissingDataBottomBar.buttons({
    super.key,
    String? primaryButtonLabel,
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonLabel,
    VoidCallback? onSecondaryPressed,
  }) : children = [
         if (primaryButtonLabel != null)
           MissingDataButton(
             key: const Key("bottom_bar_primary"),
             label: primaryButtonLabel,
             onPressed: onPrimaryPressed,
           ),
         if (secondaryButtonLabel != null)
           MissingDataButton(
             key: const Key("bottom_bar_secondary"),
             label: secondaryButtonLabel,
             style: MissingDataButtonStyle.outline,
             onPressed: onSecondaryPressed,
           ),
       ];

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final padding = MediaQuery.paddingOf(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.light,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, -1),
            blurRadius: 6,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        theme.defaultSpacing + padding.left,
        theme.defaultSpacing,
        theme.defaultSpacing + padding.right,
        max(_minBottomPadding, padding.bottom),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.smallSpacing,
        children: children,
      ),
    );
  }
}
