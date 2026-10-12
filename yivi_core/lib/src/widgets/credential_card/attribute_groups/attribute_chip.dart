import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";
import "attribute_value_formatting.dart";

/// A short fact about the holder as a small rounded chip ("Older than 21",
/// "EU citizen").
class AttributeChip extends StatelessWidget {
  final String text;
  final Color background;

  const AttributeChip({
    super.key,
    required this.text,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.smallSpacing,
        vertical: theme.tinySpacing,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: theme.borderRadius,
      ),
      child: Text(
        text,
        style: attributeLabelStyle(theme).copyWith(color: theme.dark),
      ),
    );
  }
}
