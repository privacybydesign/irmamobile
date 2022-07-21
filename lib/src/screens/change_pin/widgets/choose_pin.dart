import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../screens/change_pin/models/change_pin_bloc.dart';
import '../../../screens/change_pin/models/change_pin_state.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../pin/yivi_pin_screen.dart';

class ChoosePin extends StatelessWidget {
  static const String routeName = 'change_pin/choose_pin';

  final void Function(BuildContext, String) chooseNewPin;
  final VoidCallback toggleLongPin;
  final VoidCallback? cancel;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pinVisibilityBloc = PinVisibilityBloc();

  ChoosePin({required this.chooseNewPin, required this.toggleLongPin, this.cancel});

  @override
  Widget build(BuildContext context) {
    return YiviPinScaffold(
      key: _scaffoldKey,
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
          final pinBloc = EnterPinStateBloc(maxPinSize);
          final pinVisibilityBloc = _pinVisibilityBloc;

          void submit(String pin) {
            chooseNewPin(context, pin);
          }

          return YiviPinScreen(
            scaffoldKey: _scaffoldKey,
            instructionKey: 'change_pin.choose_pin.instruction',
            maxPinSize: maxPinSize,
            onSubmit: submit,
            pinBloc: pinBloc,
            pinVisibilityBloc: pinVisibilityBloc,
            onTogglePinSize: toggleLongPin,
            checkSecurePin: true,
            listener: (context, state) {
              if (maxPinSize == shortPinSize && state.goodEnough) {
                submit(state.toString());
              }
            },
          );
        },
      ),
    );
  }
}
