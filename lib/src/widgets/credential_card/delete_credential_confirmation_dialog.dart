import 'package:flutter/widgets.dart';

import '../irma_confirmation_dialog.dart';

class DeleteCredentialConfirmationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const IrmaConfirmationDialog(
      titleTranslationKey: 'credential.options.delete',
      contentTranslationKey: 'credential.options.confirm_delete',
      confirmTranslationKey: 'ui.delete',
    );
  }
}
