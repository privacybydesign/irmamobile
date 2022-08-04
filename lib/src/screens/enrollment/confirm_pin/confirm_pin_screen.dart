import 'package:flutter/material.dart';

import '../../pin/yivi_pin_screen.dart';
import '../../yivi_confirm_pin_scaffold.dart';

class ConfirmPinScreen extends StatelessWidget {
  static const String routeName = 'confirm_pin';
  final StringCallback submitConfirmationPin;
  final VoidCallback onPrevious;
  final ValueNotifier<String> newPinNotifier;

  const ConfirmPinScreen({
    required this.submitConfirmationPin,
    required this.onPrevious,
    required this.newPinNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: newPinNotifier,
      builder: (context, pinString, _) => YiviConfirmPinScaffold(
        submit: submitConfirmationPin,
        cancel: onPrevious,
        instructionKey: 'enrollment.choose_pin.confirm_instruction',
        longPin: pinString.length > shortPinSize,
      ),
    );
  }
}
