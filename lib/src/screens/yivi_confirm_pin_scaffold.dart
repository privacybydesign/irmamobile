import 'package:flutter/material.dart';

import '../widgets/irma_app_bar.dart';
import 'pin/yivi_pin_screen.dart';

class YiviConfirmPinScaffold extends StatelessWidget {
  final StringCallback submit;
  final VoidCallback cancel;
  final String instructionKey;
  final bool longPin;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  YiviConfirmPinScaffold({
    required this.submit,
    required this.cancel,
    required this.instructionKey,
    required this.longPin,
  });

  @override
  Widget build(BuildContext context) {
    final maxPinSize = longPin ? longPinSize : shortPinSize;
    final pinBloc = EnterPinStateBloc(maxPinSize);

    return YiviPinScaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        title: '',
        leadingAction: cancel,
        leadingTooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      body: YiviPinScreen(
        scaffoldKey: _scaffoldKey,
        instructionKey: instructionKey,
        maxPinSize: maxPinSize,
        onSubmit: submit,
        pinBloc: pinBloc,
        listener: (context, state) {
          if (maxPinSize == shortPinSize && state.pin.length == maxPinSize) {
            submit(state.toString());
          }
        },
      ),
    );
  }
}
