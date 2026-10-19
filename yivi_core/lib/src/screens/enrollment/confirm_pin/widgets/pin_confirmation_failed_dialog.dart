import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../../widgets/glass/glass_dialog.dart";
import "../../../../widgets/glass/pill_buttons.dart";
import "../../../../widgets/irma_dialog.dart";

class PinConfirmationFailedDialog extends StatelessWidget {
  final VoidCallback onPressed;

  const PinConfirmationFailedDialog({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IrmaDialog(
      icon: const ToneDisc(icon: Icons.pin_outlined, tone: DialogTone.danger),
      title: FlutterI18n.translate(context, "confirm_pin.error.title"),
      content: FlutterI18n.translate(context, "confirm_pin.error.body"),
      child: FancyPillButton(
        label: FlutterI18n.translate(context, "confirm_pin.error.action"),
        size: PillSize.regular,
        onPressed: onPressed,
      ),
    );
  }
}
