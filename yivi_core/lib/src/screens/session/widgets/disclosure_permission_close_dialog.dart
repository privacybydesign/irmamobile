import "package:flutter/material.dart";

import "../../../widgets/yivi_dialog.dart";

class DisclosurePermissionCloseDialog extends StatelessWidget {
  static Future<void> show(
    BuildContext context, {
    Function()? onConfirm,
  }) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => DisclosurePermissionCloseDialog(),
        ) ??
        false;

    if (!context.mounted) return;

    if (confirmed) {
      onConfirm == null ? Navigator.of(context).pop() : onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return YiviDialog.confirmation(
      titleTranslationKey: "disclosure_permission.confirm_close_dialog.title",
      contentTranslationKey:
          "disclosure_permission.confirm_close_dialog.explanation",
      confirmTranslationKey:
          "disclosure_permission.confirm_close_dialog.confirm",
      cancelTranslationKey:
          "disclosure_permission.confirm_close_dialog.decline",
    );
  }
}
