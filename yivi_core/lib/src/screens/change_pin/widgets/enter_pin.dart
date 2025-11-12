import 'package:flutter/material.dart';

import '../../yivi_basic_pin_scaffold.dart';

class EnterPin extends StatelessWidget {
  static const String routeName = 'change_pin/enter_pin';

  final void Function(String) submitOldPin;
  final VoidCallback? cancel;

  const EnterPin({required this.submitOldPin, this.cancel});

  @override
  Widget build(BuildContext context) {
    return YiviBasicPinScaffold(
      submit: submitOldPin,
      cancel: cancel,
      instructionKey: 'change_pin.enter_pin.instruction',
    );
  }
}
