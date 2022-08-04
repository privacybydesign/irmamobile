import 'package:flutter/material.dart';

import '../../pin/yivi_pin_screen.dart';
import '../../yivi_choose_pin_scaffold.dart';

class ChoosePinScreen extends StatelessWidget {
  static const String routeName = 'choose_pin';
  final StringCallback onChoosePin;
  final VoidCallback onPrevious;

  const ChoosePinScreen({
    required this.onChoosePin,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return YiviChoosePinScaffold(
      submit: onChoosePin,
      cancel: onPrevious,
      instructionKey: 'enrollment.choose_pin.insert_pin',
    );
  }
}
