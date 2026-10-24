import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/irma_error_scaffold_body.dart";

class EnrollmentFailedScreen extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onRetryEnrollment;

  const EnrollmentFailedScreen({
    required this.onPrevious,
    required this.onRetryEnrollment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      // The page colour, as on the other error screens.
      backgroundColor: YiviPalette.of(context).background,
      appBar: IrmaAppBar(
        titleTranslationKey: "ui.error",
        leading: YiviBackButton(onTap: onPrevious),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "ui.retry",
        onPrimaryPressed: onRetryEnrollment,
      ),
      body: const IrmaErrorScaffoldBody(type: ErrorType.general),
    );
  }
}
