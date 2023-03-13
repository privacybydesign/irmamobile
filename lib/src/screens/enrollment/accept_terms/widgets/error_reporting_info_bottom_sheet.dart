import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_sheet.dart';
import '../../../../widgets/translated_text.dart';

class ErrorReportingInfoBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Added padding to the right so the header doesn't overlap with the close button.
          Padding(
            padding: EdgeInsets.only(
              right: theme.mediumSpacing,
            ),
            child: TranslatedText(
              'enrollment.error_reporting.dialog.title',
              style: theme.textTheme.headline3,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
            child: TranslatedText(
              'enrollment.error_reporting.dialog.explanation',
              style: theme.textTheme.bodyText2,
            ),
          ),
        ],
      ),
    );
  }
}
