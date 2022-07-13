import 'package:flutter/material.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

import '../../../data/irma_preferences.dart';
import '../../pin/yivi_pin_screen.dart';

class ConfirmPin extends StatelessWidget {
  static const String routeName = 'confirm_pin';
  final Function(String) submitConfirmationPin;
  final void Function(BuildContext) cancelAndNavigate;

  const ConfirmPin({required this.submitConfirmationPin, required this.cancelAndNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: 'enrollment.choose_pin.title',
        leadingAction: () => cancelAndNavigate(context),
        leadingTooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      body: StreamBuilder(
        stream: IrmaPreferences.get().getLongPin(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          final maxPinSize = snapshot.hasData && snapshot.data! ? longPinSize : shortPinSize;
          final pinBloc = PinStateBloc(maxPinSize);
          final pinVisibilityBloc = PinVisibilityBloc();

          return YiviPinScreen(
            instructionKey: 'enrollment.choose_pin.confirm_instruction',
            maxPinSize: maxPinSize,
            onSubmit: () => submitConfirmationPin(pinBloc.state.pin.join()),
            pinBloc: pinBloc,
            pinVisibilityBloc: pinVisibilityBloc,
            checkSecurePin: true,
          );
        },
      ),
    );
  }
}
