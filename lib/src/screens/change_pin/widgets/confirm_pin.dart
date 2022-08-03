import 'package:flutter/material.dart';

import '../../pin/yivi_pin_screen.dart';
import '../../yivi_confirm_pin_scaffold.dart';
import 'confirm_pin_reset_dialog.dart';

class ConfirmPin extends StatelessWidget {
  static const String routeName = 'change_pin/confirm_pin';

  final void Function(String) confirmNewPin;
  final VoidCallback cancel;

  const ConfirmPin({required this.confirmNewPin, required this.cancel});

  StringCallback _showConfirmDialog(BuildContext context) => (String pin) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => const ConfirmPinResetDialog(),
        );

        if (confirmed ?? false) {
          confirmNewPin(pin);
        } else {
          cancel();
        }
      };

  @override
  Widget build(BuildContext context) {
    return YiviConfirmPinScaffold(
      submit: _showConfirmDialog(context),
      cancel: cancel,
      instructionKey: 'change_pin.confirm_pin.instruction',
      longPin: ModalRoute.of(context)!.settings.arguments as bool,
    );
  }
}
