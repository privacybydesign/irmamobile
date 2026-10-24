import "package:material_ui/material_ui.dart";

import "../irma_confirmation_dialog.dart";

class DeleteCredentialConfirmationDialog extends StatelessWidget {
  /// Asks whether to delete the card; true once confirmed.
  static Future<bool> ask(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => DeleteCredentialConfirmationDialog(),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    return const IrmaConfirmationDialog(
      destructive: true,
      titleTranslationKey: "credential.options.delete",
      contentTranslationKey: "credential.options.confirm_delete",
      confirmTranslationKey: "ui.delete",
    );
  }
}
