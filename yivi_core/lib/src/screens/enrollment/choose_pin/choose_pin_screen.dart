import "package:material_ui/material_ui.dart";

import "../../../widgets/irma_app_bar.dart";
import "../../pin/pin_entry.dart";
import "../../pin/yivi_pin_screen.dart";

class ChoosePinScreen extends StatelessWidget {
  static const String routeName = "choose_pin";
  final StringCallback onChoosePin;
  final VoidCallback onPrevious;
  final ValueNotifier<String> newPinNotifier;
  final String? stepLabel;

  const ChoosePinScreen({
    required this.onChoosePin,
    required this.onPrevious,
    required this.newPinNotifier,
    this.stepLabel,
  });

  @override
  Widget build(BuildContext context) {
    return YiviPinScaffold(
      appBar: IrmaAppBar(
        titleString: "",
        leading: YiviBackButton(onTap: onPrevious),
      ),
      body: PinEntry(
        mode: ChooseEntry(stepLabel: stepLabel, previous: newPinNotifier.value),
        onSubmit: (pin) {
          newPinNotifier.value = pin;
          onChoosePin(pin);
        },
      ),
    );
  }
}
