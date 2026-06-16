import "package:flutter/widgets.dart";

import "../../../widgets/yivi_dialog.dart";

class DeleteDataConfirmationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) => YiviDialog.confirmation(
    titleTranslationKey: "settings.confirm_delete_dialog.title",
    contentTranslationKey: "settings.confirm_delete_dialog.explanation",
    confirmTranslationKey: "settings.confirm_delete_dialog.confirm",
    cancelTranslationKey: "settings.confirm_delete_dialog.deny",
  );
}
