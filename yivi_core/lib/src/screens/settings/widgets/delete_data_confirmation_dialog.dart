import "package:material_ui/material_ui.dart";

import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/irma_confirmation_dialog.dart";

class DeleteDataConfirmationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const IrmaConfirmationDialog(
    icon: ToneDisc(icon: Icons.delete_outline_rounded, tone: DialogTone.danger),
    destructive: true,
    titleTranslationKey: "settings.confirm_delete_dialog.title",
    contentTranslationKey: "settings.confirm_delete_dialog.explanation",
    confirmTranslationKey: "settings.confirm_delete_dialog.confirm",
    cancelTranslationKey: "settings.confirm_delete_dialog.deny",
  );
}
