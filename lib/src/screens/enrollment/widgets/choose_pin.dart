import 'package:flutter/material.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/irma_repository_provider.dart';
import '../../pin/yivi_pin_screen.dart';

class ChoosePin extends StatelessWidget {
  static const String routeName = 'choose_pin';
  final void Function(BuildContext, String) submitPin;
  final void Function(BuildContext) cancelAndNavigate;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pinVisibilityBloc = PinVisibilityBloc();

  ChoosePin({
    required this.submitPin,
    required this.cancelAndNavigate,
  });

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
        preference: IrmaRepositoryProvider.of(context).preferences.longPin,
        builder: (BuildContext context, bool longPin) {
          final maxPinSize = longPin ? longPinSize : shortPinSize;
          final pinBloc = EnterPinStateBloc(maxPinSize);

          void submit(String pin) {
            submitPin(context, pin);
          }

          return YiviPinScreen(
            scaffoldKey: _scaffoldKey,
            instructionKey: 'enrollment.choose_pin.insert_pin',
            maxPinSize: maxPinSize,
            onSubmit: submit,
            pinBloc: pinBloc,
            pinVisibilityBloc: _pinVisibilityBloc,
            onTogglePinSize: () => preferences.setLongPin(!longPin),
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
