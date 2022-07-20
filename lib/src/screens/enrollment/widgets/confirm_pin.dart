import 'package:flutter/material.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/irma_repository_provider.dart';
import '../../pin/yivi_pin_screen.dart';

class ConfirmPin extends StatelessWidget {
  static const String routeName = 'confirm_pin';
  final Function(String) submitConfirmationPin;
  final void Function(BuildContext) cancelAndNavigate;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final pinVisibilityBloc = PinVisibilityBloc();

  ConfirmPin({required this.submitConfirmationPin, required this.cancelAndNavigate});

  @override
  Widget build(BuildContext context) {
    final preferences = IrmaRepositoryProvider.of(context).preferences;
    return YiviPinScaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        titleTranslationKey: 'enrollment.choose_pin.title',
        leadingAction: () => cancelAndNavigate(context),
        leadingTooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      body: PreferenceBuilder(
        preference: preferences.longPin,
        builder: (BuildContext context, bool longPin) {
          final maxPinSize = longPin ? longPinSize : shortPinSize;
          final pinBloc = EnterPinStateBloc(maxPinSize);

          return YiviPinScreen(
            scaffoldKey: _scaffoldKey,
            instructionKey: 'enrollment.choose_pin.confirm_instruction',
            maxPinSize: maxPinSize,
            onSubmit: submitConfirmationPin,
            pinBloc: pinBloc,
            pinVisibilityBloc: pinVisibilityBloc,
            checkSecurePin: true,
            listener: (context, state) {
              if (maxPinSize == shortPinSize &&
                  state.pin.length == maxPinSize &&
                  state.attributes.contains(SecurePinAttribute.goodEnough)) {
                submitConfirmationPin(state.toString());
              }
            },
          );
        },
      ),
    );
  }
}
