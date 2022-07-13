import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

import '../../pin/yivi_pin_screen.dart';

class EnterPin extends StatelessWidget {
  static const String routeName = 'change_pin/enter_pin';

  final void Function(String) submitOldPin;
  final VoidCallback? cancel;

  const EnterPin({required this.submitOldPin, this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(
          FlutterI18n.translate(context, 'change_pin.enter_pin.title'),
        ),
        leadingTooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        leadingAction: () async {
          cancel?.call();
          if (!await Navigator.of(context).maybePop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      ),
      body: StreamBuilder(
        stream: IrmaPreferences.get().getLongPin(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          final maxPinSize = (snapshot.hasData && snapshot.data!) ? longPinSize : shortPinSize;
          final pinBloc = PinStateBloc(maxPinSize);
          BlocListener<PinStateBloc, PinState>(
            bloc: pinBloc,
            listener: (context, state) {
              if (maxPinSize == shortPinSize) {
                submitOldPin(pinBloc.state.pin.join());
              }
            },
          );
          return YiviPinScreen(
            instructionKey: 'change_pin.enter_pin.instruction',
            maxPinSize: maxPinSize,
            onSubmit: () => submitOldPin(pinBloc.state.pin.join()),
            pinBloc: pinBloc,
            pinVisibilityBloc: PinVisibilityBloc(),
          );
        },
      ),
    );
  }
}
