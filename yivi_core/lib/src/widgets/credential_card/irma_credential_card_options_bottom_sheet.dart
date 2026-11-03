import "package:material_ui/material_ui.dart";

import "../../theme/theme.dart";
import "../irma_divider.dart";
import "../translated_text.dart";

class IrmaCredentialCardOptionsBottomSheet extends StatelessWidget {
  final VoidCallback? onDelete;
  final VoidCallback? onReobtain;

  /// Switches the card between its layout and a plain list of attributes;
  /// null when the card has no layout to switch from.
  final VoidCallback? onToggleRawList;

  /// The card currently shows the plain list.
  final bool rawList;

  const IrmaCredentialCardOptionsBottomSheet({
    required this.onDelete,
    required this.onReobtain,
    this.onToggleRawList,
    this.rawList = false,
  });

  Widget _buildOptionTile({
    required IconData icon,
    required String translationKey,
    required IrmaThemeData theme,
    Key? key,
    Function()? onTap,
  }) {
    // Wrap in a transparent Material so the tile's ink splashes have a surface
    // to paint on: this sheet's container (YiviBottomSheet) is a DecoratedBox
    // with a background color, which would otherwise hide the splashes painted
    // on the Material further up the tree.
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        key: key,
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
    final tiles = [
      if (onToggleRawList != null)
        _buildOptionTile(
          theme: theme,
          key: const Key("card_option_toggle_raw_list"),
          icon: rawList ? Icons.badge_outlined : Icons.view_list_outlined,
          translationKey: rawList
              ? "credential.options.show_as_card"
              : "credential.options.show_as_list",
          onTap: onToggleRawList,
        ),
      if (onReobtain != null)
        _buildOptionTile(
          theme: theme,
          icon: Icons.cached,
          translationKey: "credential.options.reobtain",
          onTap: onReobtain,
        ),
      if (onDelete != null)
        _buildOptionTile(
          theme: theme,
          icon: Icons.delete,
          translationKey: "credential.options.delete",
          onTap: onDelete,
        ),
    ];

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
          for (final (i, tile) in tiles.indexed) ...[
            if (i > 0) const IrmaDivider(),
            tile,
          ],
        ],
      ),
    );
  }
}
