import "package:flutter/material.dart";

import "../../../../theme/theme.dart";
import "../../../../widgets/translated_text.dart";

class ErrorReportingInfoBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.yivi.spacing.base),
      child: TranslatedText(
        "enrollment.error_reporting.dialog.explanation",
        style: context.text.bodyMedium,
      ),
    );
  }
}
