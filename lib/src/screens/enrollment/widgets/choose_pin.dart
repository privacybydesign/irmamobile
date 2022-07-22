import 'package:flutter/material.dart';

import '../../yivi_choose_pin_scaffold.dart';

class ChoosePin extends StatelessWidget {
  static const String routeName = 'choose_pin';
  final void Function(BuildContext, String) submitPin;
  final void Function(BuildContext) cancelAndNavigate;

  const ChoosePin({
    required this.submitPin,
    required this.cancelAndNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return YiviChoosePinScaffold(
      submit: (pin) => submitPin(context, pin),
      cancel: () => cancelAndNavigate(context),
      titleTranslationKey: 'enrollment.choose_pin.title',
      instructionKey: 'enrollment.choose_pin.insert_pin',
    );
  }
}
