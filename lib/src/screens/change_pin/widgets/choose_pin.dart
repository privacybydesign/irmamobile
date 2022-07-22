import 'package:flutter/material.dart';

import '../../yivi_choose_pin_scaffold.dart';

class ChoosePin extends StatelessWidget {
  static const String routeName = 'change_pin/choose_pin';

  final void Function(BuildContext, String) chooseNewPin;
  final VoidCallback cancel;

  const ChoosePin({required this.chooseNewPin, required this.cancel});

  @override
  Widget build(BuildContext context) {
    return YiviChoosePinScaffold(
      submit: (pin) => chooseNewPin(context, pin),
      cancel: cancel,
      titleTranslationKey: 'change_pin.choose_pin.title',
      instructionKey: 'change_pin.choose_pin.instruction',
    );
  }
}
