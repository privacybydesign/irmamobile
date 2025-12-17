import "package:flutter/material.dart";

import "../../../../widgets/irma_confirmation_dialog.dart";

class CertManagementWarningDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const IrmaConfirmationDialog(
    titleTranslationKey: "debug.cert_management.warning_dialog.title",
    contentTranslationKey: "debug.cert_management.warning_dialog.content",
  );
}
