import "package:material_ui/material_ui.dart";

import "../../widgets/error_status_screen.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_bottom_bar.dart";

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
      actions: IrmaBottomBar(
        primaryButtonLabel: "ui.retry",
        onPrimaryPressed: onRetryEnrollment,
      ),
      type: ErrorType.general,
    );
  }
}
