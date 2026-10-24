import "package:material_ui/material_ui.dart";

import "../glass/glass_dialog.dart";

/// Asks whether to delete a card; true once confirmed.
Future<bool> confirmDeleteCredential(BuildContext context) => showConfirmDialog(
  context,
  destructive: true,
  titleKey: "credential.options.delete",
  messageKey: "credential.options.confirm_delete",
  confirmKey: "ui.delete",
);
