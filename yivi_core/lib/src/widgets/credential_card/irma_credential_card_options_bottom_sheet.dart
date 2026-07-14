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
    required BuildContext context,
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
        leading: Icon(icon, color: context.colors.secondary),
        title: TranslatedText(
          translationKey,
          style: context.text.bodyMedium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.yivi.spacing.base,
        0,
        context.yivi.spacing.base,
        context.yivi.spacing.base,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onReobtain != null)
            _buildOptionTile(
              context: context,
              icon: Icons.cached,
              translationKey: "credential.options.reobtain",
              onTap: onReobtain,
            ),
          if (onReobtain != null && onDelete != null) const IrmaDivider(),
          if (onDelete != null)
            _buildOptionTile(
              context: context,
              icon: Icons.delete,
              translationKey: "credential.options.delete",
              onTap: onDelete,
            ),
        ],
      ),
    );
  }
}
