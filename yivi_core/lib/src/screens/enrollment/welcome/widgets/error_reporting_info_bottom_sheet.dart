import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";
import "../../../../theme/yivi_space.dart";
import "../../../../widgets/text/translated_text.dart";
import "../../widgets/enrollment_sheet_hero.dart";

/// What error reports send: the step's bug picture, then the explanation.
class ErrorReportingInfoBottomSheet extends StatelessWidget {
  const ErrorReportingInfoBottomSheet();

  @override
  Widget build(BuildContext context) {
    final theme = YiviTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(YiviSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EnrollmentSheetHero(icon: Icons.bug_report_outlined),
          TranslatedText(
            "enrollment.error_reporting.dialog.explanation",
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
