import 'package:flutter/widgets.dart';

import '../../../widgets/irma_confirmation_dialog.dart';

class DeleteAllCredentialsConfirmationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const IrmaConfirmationDialog(
    titleTranslationKey: 'debug.delete_credentials.dialog.title',
    contentTranslationKey: 'debug.delete_credentials.dialog.content',
  );
}
