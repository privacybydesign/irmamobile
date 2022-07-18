import 'dart:async';

import 'package:flutter/material.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

import '../../../data/irma_preferences.dart';
import '../../pin/yivi_pin_screen.dart';

class ChoosePin extends StatelessWidget {
  static const String routeName = 'choose_pin';
  final void Function(BuildContext, String) submitPin;
  final void Function(BuildContext) cancelAndNavigate;
  final pinSizeStreamController = StreamController<int>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pinVisibilityBloc = PinVisibilityBloc();

  ChoosePin({
    required this.submitPin,
    required this.cancelAndNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return YiviPinScaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        titleTranslationKey: 'enrollment.choose_pin.title',
        leadingAction: () => cancelAndNavigate(context),
        leadingTooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      body: StreamBuilder<int>(
        stream: pinSizeStreamController.stream,
        builder: (context, snapshot) {
          final maxPinSize = snapshot.hasData ? snapshot.data! : shortPinSize;
          final pinBloc = EnterPinStateBloc(maxPinSize);

          void onSubmit() {
            IrmaPreferences.get().setLongPin(maxPinSize == longPinSize);
            submitPin(context, pinBloc.state.pin.join());
          }

          return YiviPinScreen(
            scaffoldKey: _scaffoldKey,
            instructionKey: 'enrollment.choose_pin.insert_pin',
            maxPinSize: maxPinSize,
            onSubmit: onSubmit,
            pinBloc: pinBloc,
            pinVisibilityBloc: _pinVisibilityBloc,
            onTogglePinSize: () => pinSizeStreamController.add(maxPinSize == shortPinSize ? longPinSize : shortPinSize),
            checkSecurePin: true,
            listener: (context, state) {
              if (maxPinSize == shortPinSize &&
                  state.pin.length == maxPinSize &&
                  state.attributes.contains(SecurePinAttribute.goodEnough)) {
                onSubmit();
              }
            },
          );
        },
      ),
    );
  }
}
