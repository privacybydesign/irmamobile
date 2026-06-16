import "package:flutter/widgets.dart";

import "../yivi_dialog.dart";

class DeleteCredentialConfirmationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return YiviDialog.confirmation(
      titleTranslationKey: "credential.options.delete",
      contentTranslationKey: "credential.options.confirm_delete",
      confirmTranslationKey: "ui.delete",
    );
  }
}
