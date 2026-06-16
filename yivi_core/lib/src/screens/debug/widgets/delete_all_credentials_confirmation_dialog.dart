import "package:flutter/widgets.dart";

import "../../../widgets/yivi_dialog.dart";

class DeleteAllCredentialsConfirmationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) => YiviDialog.confirmation(
    titleTranslationKey: "debug.delete_credentials.dialog.title",
    contentTranslationKey: "debug.delete_credentials.dialog.content",
  );
}
