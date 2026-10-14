import "package:material_ui/material_ui.dart";

import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/irma_confirmation_dialog.dart";

class ConfirmPinResetDialog extends StatelessWidget {
  const ConfirmPinResetDialog({super.key});

  @override
  Widget build(BuildContext context) => const IrmaConfirmationDialog(
    icon: ToneDisc(icon: Icons.password_rounded),
    contentTranslationKey: "change_pin.dialog.body",
    titleTranslationKey: "change_pin.dialog.title",
    cancelTranslationKey: "change_pin.dialog.cancel",
    confirmTranslationKey: "change_pin.dialog.ok",
  );
}
