import "package:flutter/material.dart";

import "../../theme/theme.dart";
import "../irma_divider.dart";
import "../translated_text.dart";

class IrmaCredentialCardOptionsBottomSheet extends StatelessWidget {
  final VoidCallback? onDelete;
  final VoidCallback? onReobtain;

  const IrmaCredentialCardOptionsBottomSheet({
    required this.onDelete,
    required this.onReobtain,
  });

  Widget _buildOptionTile({
    required IconData icon,
    required String translationKey,
    required IrmaThemeData theme,
    Function()? onTap,
  }) {
    // Wrap in a transparent Material so the tile's ink splashes have a surface
    // to paint on: this sheet's container (YiviBottomSheet) is a DecoratedBox
    // with a background color, which would otherwise hide the splashes painted
    // on the Material further up the tree.
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 0,
        leading: Icon(icon, color: theme.themeData.colorScheme.secondary),
        title: TranslatedText(
          translationKey,
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.defaultSpacing,
        0,
        theme.defaultSpacing,
        theme.defaultSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onReobtain != null)
            _buildOptionTile(
              theme: theme,
              icon: Icons.cached,
              translationKey: "credential.options.reobtain",
              onTap: onReobtain,
            ),
          if (onReobtain != null && onDelete != null) const IrmaDivider(),
          if (onDelete != null)
            _buildOptionTile(
              theme: theme,
              icon: Icons.delete,
              translationKey: "credential.options.delete",
              onTap: onDelete,
            ),
        ],
      ),
    );
  }
}
