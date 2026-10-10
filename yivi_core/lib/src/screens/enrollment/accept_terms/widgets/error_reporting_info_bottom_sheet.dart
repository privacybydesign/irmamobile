import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";
import "../../../../widgets/translated_text.dart";

class ErrorReportingInfoBottomSheet extends StatelessWidget {
  /// Left and right padding; the theme's default spacing when null.
  final double? sidePadding;

  const ErrorReportingInfoBottomSheet({this.sidePadding});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: sidePadding ?? theme.defaultSpacing,
        vertical: theme.defaultSpacing,
      ),
      child: TranslatedText(
        "enrollment.error_reporting.dialog.explanation",
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
