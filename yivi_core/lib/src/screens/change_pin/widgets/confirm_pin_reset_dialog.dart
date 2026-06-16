import "package:flutter/material.dart";

import "../../../widgets/yivi_dialog.dart";

class ConfirmPinResetDialog extends StatelessWidget {
  const ConfirmPinResetDialog({super.key});

  @override
  Widget build(BuildContext context) => YiviDialog.confirmation(
    contentTranslationKey: "change_pin.dialog.body",
    titleTranslationKey: "change_pin.dialog.title",
    cancelTranslationKey: "change_pin.dialog.cancel",
    confirmTranslationKey: "change_pin.dialog.ok",
  );
}
