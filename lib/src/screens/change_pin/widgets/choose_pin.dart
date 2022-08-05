import 'package:flutter/material.dart';

import '../../pin/yivi_pin_screen.dart';
import '../../yivi_choose_pin_scaffold.dart';

class ChoosePin extends StatelessWidget {
  static const String routeName = 'choose_pin';

  final StringCallback chooseNewPin;
  final VoidCallback cancel;
  final ValueNotifier<String> newPinNotifier;

  const ChoosePin({
    required this.chooseNewPin,
    required this.cancel,
    required this.newPinNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return YiviChoosePinScaffold(
      submit: chooseNewPin,
      onBack: cancel,
      instructionKey: 'change_pin.choose_pin.instruction',
      newPinNotifier: newPinNotifier,
    );
  }
}
