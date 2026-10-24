import "package:material_ui/material_ui.dart";

import "../../../widgets/glass/glass_dialog.dart";
import "../../pin/yivi_pin_screen.dart";
import "../../yivi_confirm_pin_scaffold.dart";

class ConfirmPin extends StatelessWidget {
  static const String routeName = "change_pin/confirm_pin";

  final StringCallback confirmNewPin;
  final VoidCallback cancel, returnToChoosePin, onPinMismatch;
  final ValueNotifier<String> newPinNotifier;

  const ConfirmPin({
    required this.confirmNewPin,
    required this.cancel,
    required this.returnToChoosePin,
    required this.onPinMismatch,
    required this.newPinNotifier,
  });

  StringCallback _showConfirmDialog(BuildContext context) {
    return (String pin) async {
      final confirmed = await showConfirmDialog(
        context,
        icon: const ToneDisc(icon: Icons.password_rounded),
        titleKey: "change_pin.dialog.title",
        messageKey: "change_pin.dialog.body",
        confirmKey: "change_pin.dialog.ok",
        cancelKey: "change_pin.dialog.cancel",
      );

      if (confirmed) {
        confirmNewPin(pin);
      } else {
        cancel();
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return YiviConfirmPinScaffold(
      submit: _showConfirmDialog(context),
      onBack: returnToChoosePin,
      instructionKey: "change_pin.confirm_pin.instruction",
      onPinMismatch: onPinMismatch,
      newPinNotifier: newPinNotifier,
    );
  }
}
