import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";
import "../../../translated_text.dart";
import "../../../yivi_bottom_sheet.dart";

/// Whether the document's chip proved it is the original: a green "Chip is
/// genuine" pill, or a grey "Only signature checked" one, followed by an info
/// button that explains what that means.
class ChipCheckPill extends StatelessWidget {
  final bool genuine;

  const ChipCheckPill({required this.genuine})
    : super(key: const Key("chip_check_pill"));

  static const _prefix = "credential.chip_check";

  void _explain(BuildContext context) {
    showYiviBottomSheet(
      context: context,
      titleKey: "$_prefix.info_title",
      child: Padding(
        key: const Key("chip_check_info"),
        padding: EdgeInsets.fromLTRB(
          IrmaTheme.of(context).defaultSpacing,
          0,
          IrmaTheme.of(context).defaultSpacing,
          IrmaTheme.of(context).defaultSpacing,
        ),
        child: TranslatedText(
          genuine ? "$_prefix.info_genuine" : "$_prefix.info_signature_only",
          style: IrmaTheme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final (background, foreground, iconColor, icon) = genuine
        ? (
            theme.successSurface,
            theme.onSuccessSurface,
            theme.success,
            Icons.verified_user,
          )
        : (
            theme.neutralExtraLight,
            theme.neutralExtraDark,
            theme.neutralDark,
            Icons.shield_outlined,
          );

    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: .min,
              spacing: 6,
              children: [
                Icon(icon, size: 16, color: iconColor),
                Flexible(
                  child: TranslatedText(
                    genuine ? "$_prefix.genuine" : "$_prefix.signature_only",
                    style: TextStyle(
                      fontFamily: theme.secondaryFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // The icon is small; the button around it is a full tap target.
        IconButton(
          key: const Key("chip_check_info_button"),
          tooltip: FlutterI18n.translate(context, "$_prefix.info_label"),
          onPressed: () => _explain(context),
          icon: Icon(Icons.info_outline, size: 20, color: theme.neutralDark),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ],
    );
  }
}
