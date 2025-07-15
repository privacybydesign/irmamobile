import 'package:flutter/material.dart';

import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_error_scaffold_body.dart';

class EnrollmentFailedScreen extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onRetryEnrollment;

  const EnrollmentFailedScreen({required this.onPrevious, required this.onRetryEnrollment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: 'ui.error',
        leading: YiviBackButton(onTap: onPrevious),
      ),
      bottomNavigationBar: IrmaBottomBar(primaryButtonLabel: 'ui.retry', onPrimaryPressed: onRetryEnrollment),
      body: const IrmaErrorScaffoldBody(type: ErrorType.general),
    );
  }
}
