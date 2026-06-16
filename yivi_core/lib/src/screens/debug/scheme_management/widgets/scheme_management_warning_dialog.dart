import "package:flutter/material.dart";

import "../../../../widgets/yivi_dialog.dart";

class SchemeManagementWarningDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) => YiviDialog.confirmation(
    titleTranslationKey: "debug.scheme_management.warning_dialog.title",
    contentTranslationKey: "debug.scheme_management.warning_dialog.content",
  );
}
