import 'package:flutter/material.dart';

import '../widgets/irma_app_bar.dart';

import 'pin/yivi_pin_screen.dart';

class YiviConfirmPinScaffold extends StatelessWidget {
  final StringCallback submit;
  final VoidCallback onBack, onPinMismatch;
  final String instructionKey;
  final bool longPin;
  final ValueNotifier<String> newPinNotifier;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  YiviConfirmPinScaffold({
    required this.submit,
    required this.onBack,
    required this.instructionKey,
    required this.newPinNotifier,
    required this.onPinMismatch,
  }) : longPin = newPinNotifier.value.length > shortPinSize;

  void _comparePins(String newPin) {
    (newPinNotifier.value == newPin) ? submit(newPin) : onPinMismatch();
  }

  @override
  Widget build(BuildContext context) {
    final maxPinSize = longPin ? longPinSize : shortPinSize;
    final pinBloc = EnterPinStateBloc(maxPinSize);

    return YiviPinScaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        title: '',
        leadingAction: onBack,
        leadingTooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      body: YiviPinScreen(
        scaffoldKey: _scaffoldKey,
        instructionKey: instructionKey,
        maxPinSize: maxPinSize,
        onSubmit: _comparePins,
        pinBloc: pinBloc,
        listener: (context, state) {
          if (maxPinSize == shortPinSize && state.pin.length == maxPinSize) {
            _comparePins(state.toString());
          }
        },
      ),
    );
  }
}
