import "package:material_ui/material_ui.dart";

import "../../util/i18n.dart";
import "../../widgets/bars/action_bar.dart";
import "../../widgets/bars/app_bar.dart";
import "../../widgets/feedback/error_status_screen.dart";

class EnrollmentFailedScreen extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onRetryEnrollment;

  const EnrollmentFailedScreen({
    required this.onPrevious,
    required this.onRetryEnrollment,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStatusScreen(
      appBar: YiviAppBar(
        titleTranslationKey: "ui.error",
        leading: YiviBackButton(onTap: onPrevious),
      ),
      actions: ActionBar.single(
        label: context.tr("ui.retry"),
        onTap: onRetryEnrollment,
      ),
      type: ErrorType.general,
    );
  }
}
