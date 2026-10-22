import "package:material_ui/material_ui.dart";

import "../../pin/yivi_pin_screen.dart";
import "../../yivi_choose_pin_scaffold.dart";

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
    return YiviChoosePinScaffold(
      stepLabel: stepLabel,
      newPinNotifier: newPinNotifier,
      submit: onChoosePin,
      onBack: onPrevious,
    );
  }
}
