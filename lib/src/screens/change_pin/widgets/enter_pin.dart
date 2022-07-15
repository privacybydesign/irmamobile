import 'package:flutter/material.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

import '../../pin/yivi_pin_screen.dart';

class EnterPin extends StatelessWidget {
  static const String routeName = 'change_pin/enter_pin';

  final void Function(String) submitOldPin;
  final VoidCallback? cancel;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  EnterPin({required this.submitOldPin, this.cancel});

  @override
  Widget build(BuildContext context) {
    return YiviPinScaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        titleTranslationKey: 'change_pin.enter_pin.title',
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
          void submit() => submitOldPin(pinBloc.state.pin.join());

          return YiviPinScreen(
              scaffoldKey: _scaffoldKey,
              instructionKey: 'change_pin.enter_pin.instruction',
              maxPinSize: maxPinSize,
              onSubmit: submit,
              pinBloc: pinBloc,
              pinVisibilityBloc: PinVisibilityBloc(),
              listener: (context, state) {
                if (maxPinSize == shortPinSize) {
                  submit();
                }
              });
        },
      ),
    );
  }
}
