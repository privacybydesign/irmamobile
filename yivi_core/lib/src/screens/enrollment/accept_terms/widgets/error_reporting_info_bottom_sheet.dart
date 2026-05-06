import "package:flutter/material.dart";

import "../../../../theme/theme.dart";
import "../../../../widgets/translated_text.dart";

class ErrorReportingInfoBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.all(theme.defaultSpacing),
      child: TranslatedText(
        "enrollment.error_reporting.dialog.explanation",
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
