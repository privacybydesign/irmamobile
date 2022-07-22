import 'package:flutter/material.dart';

import '../../yivi_confirm_pin_scaffold.dart';

class ConfirmPin extends StatelessWidget {
  static const String routeName = 'confirm_pin';
  final Function(String) submitConfirmationPin;
  final void Function(BuildContext) cancelAndNavigate;

  const ConfirmPin({required this.submitConfirmationPin, required this.cancelAndNavigate});

  @override
  Widget build(BuildContext context) {
    return YiviConfirmPinScaffold(
      submit: submitConfirmationPin,
      cancel: () => cancelAndNavigate(context),
      titleTranslationKey: 'enrollment.choose_pin.title',
      instructionKey: 'enrollment.choose_pin.confirm_instruction',
    );
  }
}
