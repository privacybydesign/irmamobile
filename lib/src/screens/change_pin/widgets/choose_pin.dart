import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_state.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

import '../../pin/yivi_pin_screen.dart';

class ChoosePin extends StatelessWidget {
  static const String routeName = 'change_pin/choose_pin';

  final void Function(BuildContext, String) chooseNewPin;
  final VoidCallback toggleLongPin;
  final VoidCallback? cancel;

  const ChoosePin({required this.chooseNewPin, required this.toggleLongPin, this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: 'change_pin.choose_pin.title',
        leadingTooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        leadingAction: () async {
          cancel?.call();
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
      body: BlocBuilder<ChangePinBloc, ChangePinState>(
        builder: (context, state) {
          final maxPinSize = state.longPin ? longPinSize : shortPinSize;
          final pinBloc = PinStateBloc(maxPinSize);
          final pinVisibilityBloc = PinVisibilityBloc();
          BlocListener<PinStateBloc, PinState>(
            bloc: pinBloc,
            listener: (context, state) {
              if (maxPinSize == shortPinSize) {
                chooseNewPin(context, pinBloc.state.pin.join());
              }
            },
          );
          return YiviPinScreen(
            instructionKey: 'change_pin.choose_pin.instruction',
            maxPinSize: maxPinSize,
            onSubmit: () => chooseNewPin(context, pinBloc.state.pin.join()),
            pinBloc: pinBloc,
            pinVisibilityBloc: pinVisibilityBloc,
            onTogglePinSize: toggleLongPin,
            checkSecurePin: true,
          );
        },
      ),
    );
  }
}
