import 'package:flutter/material.dart';

import '../../pin/yivi_pin_screen.dart';
import '../../yivi_confirm_pin_scaffold.dart';

class ConfirmPinScreen extends StatelessWidget {
  static const String routeName = 'confirm_pin';
  final StringCallback submitConfirmationPin;
  final VoidCallback onPrevious;
  final ValueNotifier<String> newPinNotifier;
  final VoidCallback onPinMismatch;

  const ConfirmPinScreen({
    required this.submitConfirmationPin,
    required this.onPrevious,
    required this.newPinNotifier,
    required this.onPinMismatch,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: newPinNotifier,
      builder: (context, pinString, _) => YiviConfirmPinScaffold(
        submit: submitConfirmationPin,
        onBack: onPrevious,
        instructionKey: 'enrollment.choose_pin.confirm_instruction',
        newPinNotifier: newPinNotifier,
        onPinMismatch: onPinMismatch,
      ),
    );
  }
}
