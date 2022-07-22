import 'package:flutter/material.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

import '../widgets/irma_app_bar.dart';
import '../widgets/irma_repository_provider.dart';
import 'pin/yivi_pin_screen.dart';

class YiviChoosePinScaffold extends StatelessWidget {
  final StringCallback submit;
  final VoidCallback cancel;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final String titleTranslationKey;
  final String instructionKey;

  YiviChoosePinScaffold({
    required this.submit,
    required this.cancel,
    required this.titleTranslationKey,
    required this.instructionKey,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = IrmaRepositoryProvider.of(context).preferences;
    return YiviPinScaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        titleTranslationKey: titleTranslationKey,
        leadingAction: cancel,
        leadingTooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      body: PreferenceBuilder(
        preference: prefs.longPin,
        builder: (BuildContext context, bool longPin) {
          final maxPinSize = longPin ? longPinSize : shortPinSize;
          final pinBloc = EnterPinStateBloc(maxPinSize);

          return YiviPinScreen(
            scaffoldKey: _scaffoldKey,
            instructionKey: instructionKey,
            maxPinSize: maxPinSize,
            onSubmit: submit,
            pinBloc: pinBloc,
            onTogglePinSize: () => prefs.setLongPin(!longPin),
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
