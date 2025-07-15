import 'package:flutter/material.dart';

import '../../../../widgets/irma_confirmation_dialog.dart';

class SchemeManagementWarningDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const IrmaConfirmationDialog(
    titleTranslationKey: 'debug.scheme_management.warning_dialog.title',
    contentTranslationKey: 'debug.scheme_management.warning_dialog.content',
  );
}
