import "package:flutter/material.dart";

import "../../../../widgets/yivi_dialog.dart";

class CertManagementWarningDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) => YiviDialog.confirmation(
    titleTranslationKey: "debug.cert_management.warning_dialog.title",
    contentTranslationKey: "debug.cert_management.warning_dialog.content",
  );
}
