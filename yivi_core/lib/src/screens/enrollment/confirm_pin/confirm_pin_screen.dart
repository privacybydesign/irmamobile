import "package:material_ui/material_ui.dart";

import "../../../widgets/bars/irma_app_bar.dart";
import "../../pin/pin_entry.dart";
import "../../pin/yivi_pin_screen.dart";

class ConfirmPinScreen extends StatelessWidget {
  static const String routeName = "confirm_pin";
  final StringCallback submitConfirmationPin;
  final VoidCallback onPrevious;
  final ValueNotifier<String> newPinNotifier;
  final String? stepLabel;
  final VoidCallback onPinMismatch;

  const ConfirmPinScreen({
    required this.submitConfirmationPin,
    required this.onPrevious,
    required this.newPinNotifier,
    this.stepLabel,
    required this.onPinMismatch,
  });

  @override
  Widget build(BuildContext context) {
    return YiviPinScaffold(
      appBar: IrmaAppBar(
        titleString: "",
        leading: YiviBackButton(onTap: onPrevious),
      ),
      body: PinEntry(
        mode: ConfirmEntry(
          chosen: newPinNotifier.value,
          instructionKey: "enrollment.confirm_pin.instruction",
          onMismatch: onPinMismatch,
          stepLabel: stepLabel,
        ),
        onSubmit: submitConfirmationPin,
      ),
    );
  }
}
