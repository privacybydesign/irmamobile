import 'package:flutter/material.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

import '../../../widgets/irma_repository_provider.dart';
import '../../pin/yivi_pin_screen.dart';

class EnterPin extends StatelessWidget {
  static const String routeName = 'change_pin/enter_pin';

  final void Function(String) submitOldPin;
  final VoidCallback? cancel;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pinVisibilityBloc = PinVisibilityBloc();

  EnterPin({required this.submitOldPin, this.cancel});

  @override
  Widget build(BuildContext context) {
    final preferences = IrmaRepositoryProvider.of(context).preferences;
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
      body: PreferenceBuilder(
        preference: preferences.longPin,
        builder: (BuildContext context, bool longPin) {
          final maxPinSize = longPin ? longPinSize : shortPinSize;
          final pinBloc = EnterPinStateBloc(maxPinSize);

          return YiviPinScreen(
              instructionKey: 'change_pin.enter_pin.instruction',
              maxPinSize: maxPinSize,
              onSubmit: submitOldPin,
              pinBloc: pinBloc,
              pinVisibilityBloc: _pinVisibilityBloc,
              listener: (context, state) {
                if (maxPinSize == shortPinSize && state.pin.length == maxPinSize) {
                  submitOldPin(state.toString());
                }
              });
        },
      ),
    );
  }
}
