import 'package:flutter/material.dart';

import '../../pin/yivi_pin_screen.dart';
import '../../yivi_confirm_pin_scaffold.dart';
import 'confirm_pin_reset_dialog.dart';

class ConfirmPin extends StatelessWidget {
  static const String routeName = 'change_pin/confirm_pin';

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
      final bool? confirmed = await showDialog(
        context: context,
        builder: (BuildContext context) => const ConfirmPinResetDialog(),
      );

      if (confirmed ?? false) {
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
      instructionKey: 'change_pin.confirm_pin.instruction',
      onPinMismatch: onPinMismatch,
      newPinNotifier: newPinNotifier,
    );
  }
}
