import "package:material_ui/material_ui.dart";

import "../../util/i18n.dart";
import "../../widgets/action_bar.dart";
import "../../widgets/error_status_screen.dart";
import "../../widgets/irma_app_bar.dart";

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
      appBar: IrmaAppBar(
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
