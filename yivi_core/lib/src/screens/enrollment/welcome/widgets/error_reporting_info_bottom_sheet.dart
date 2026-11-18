import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";
import "../../../../theme/yivi_space.dart";
import "../../../../widgets/text/translated_text.dart";

class ErrorReportingInfoBottomSheet extends StatelessWidget {
  const ErrorReportingInfoBottomSheet();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(YiviSpace.x16),
      child: TranslatedText(
        "enrollment.error_reporting.dialog.explanation",
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
