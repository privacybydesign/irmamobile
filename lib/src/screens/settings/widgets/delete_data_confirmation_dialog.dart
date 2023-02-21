import 'package:flutter/widgets.dart';

import '../../../widgets/irma_confirmation_dialog.dart';

class DeleteDataConfirmationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const IrmaConfirmationDialog(
        titleTranslationKey: 'settings.confirm_delete_dialog.title',
        contentTranslationKey: 'settings.confirm_delete_dialog.explanation',
        confirmTranslationKey: 'settings.confirm_delete_dialog.confirm',
        cancelTranslationKey: 'settings.confirm_delete_dialog.deny',
      );
}
