import 'package:flutter/material.dart';

import '../../yivi_choose_pin_scaffold.dart';

class ChoosePin extends StatelessWidget {
  static const String routeName = 'choose_pin';

  final void Function(BuildContext, String) chooseNewPin;
  final VoidCallback cancel, returnToChoosePin;

  const ChoosePin({
    required this.chooseNewPin,
    required this.cancel,
    required this.returnToChoosePin,
  });

  @override
  Widget build(BuildContext context) {
    return YiviChoosePinScaffold(
      submit: (pin) => chooseNewPin(context, pin),
      cancel: returnToChoosePin,
      instructionKey: 'change_pin.choose_pin.instruction',
    );
  }
}
