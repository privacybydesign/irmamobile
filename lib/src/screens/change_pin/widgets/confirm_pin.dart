import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../screens/change_pin/models/change_pin_bloc.dart';
import '../../../screens/change_pin/models/change_pin_state.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../pin/yivi_pin_screen.dart';

class ConfirmPin extends StatelessWidget {
  static const String routeName = 'change_pin/confirm_pin';

  final void Function(String) confirmNewPin;
  final VoidCallback? cancel;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pinVisibilityBloc = PinVisibilityBloc();

  ConfirmPin({required this.confirmNewPin, this.cancel});

  @override
  Widget build(BuildContext context) {
    return YiviPinScaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        titleTranslationKey: 'change_pin.confirm_pin.title',
        leadingAction: () async {
          cancel?.call();
          if (!await Navigator.of(context).maybePop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
        leadingTooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      ),
      body: BlocBuilder<ChangePinBloc, ChangePinState>(builder: (context, state) {
        final maxPinSize = state.longPin ? longPinSize : shortPinSize;
        final pinBloc = EnterPinStateBloc(maxPinSize);

        return YiviPinScreen(
          scaffoldKey: _scaffoldKey,
          instructionKey: 'change_pin.confirm_pin.instruction',
          maxPinSize: maxPinSize,
          onSubmit: confirmNewPin,
          pinBloc: pinBloc,
          pinVisibilityBloc: _pinVisibilityBloc,
          checkSecurePin: true,
          listener: (context, state) {
            if (maxPinSize == shortPinSize &&
                state.pin.length == maxPinSize &&
                state.attributes.contains(SecurePinAttribute.goodEnough)) {
              confirmNewPin(state.toString());
            }
          },
        );
      }),
    );
  }
}
