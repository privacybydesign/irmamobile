import "package:material_ui/material_ui.dart";

import "../../data/irma_repository.dart";
import "../../models/log_entry.dart";
import "../glass/glass_dialog.dart";

/// Asks whether to delete a card; true once confirmed.
Future<bool> confirmDeleteCredential(BuildContext context) => showConfirmDialog(
  context,
  destructive: true,
  titleKey: "credential.options.delete",
  messageKey: "credential.options.confirm_delete",
  confirmKey: "ui.delete",
);

/// Asks whether to delete the card with [instanceIds] and, once confirmed
/// (and [context] is still there), deletes it from [repository]. True when
/// it was deleted.
Future<bool> confirmAndDeleteCredential(
  BuildContext context,
  IrmaRepository repository,
  Map<CredentialFormat, String> instanceIds,
) async {
  final confirmed = await confirmDeleteCredential(context);
  if (!confirmed || !context.mounted) return false;
  repository.deleteCredential(instanceIds);
  return true;
}
