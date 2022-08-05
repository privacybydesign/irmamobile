import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/irma_app_bar.dart';
import '../widgets/irma_repository_provider.dart';
import 'pin/yivi_pin_screen.dart';

class YiviChoosePinScaffold extends StatelessWidget {
  final StringCallback submit;
  final VoidCallback onBack;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final String instructionKey;
  final ValueNotifier<String> newPinNotifier;

  YiviChoosePinScaffold({
    required this.submit,
    required this.onBack,
    required this.instructionKey,
    required this.newPinNotifier,
  });

  void _submit(String pin) {
    newPinNotifier.value = pin;
    submit(pin);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = IrmaRepositoryProvider.of(context).preferences;

    return YiviPinScaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        title: '',
        leadingAction: onBack,
        leadingTooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      body: StreamBuilder<bool>(
        stream: prefs.getLongPin(),
        builder: (context, snapshot) {
          final toggleValue = ValueNotifier<bool>(newPinNotifier.value.isNotEmpty
              ? newPinNotifier.value.length > shortPinSize
              : (snapshot.data ?? false));
          return ValueListenableBuilder<bool>(
            valueListenable: toggleValue,
            builder: (context, longPin, _) {
              final maxPinSize = longPin ? longPinSize : shortPinSize;
              final pinBloc = EnterPinStateBloc(maxPinSize);

              return YiviPinScreen(
                scaffoldKey: _scaffoldKey,
                instructionKey: instructionKey,
                maxPinSize: maxPinSize,
                onSubmit: _submit,
                pinBloc: pinBloc,
                onTogglePinSize: () => toggleValue.value = !toggleValue.value,
                displayPinLength: true,
                checkSecurePin: true,
                listener: (context, state) {
                  if (maxPinSize == shortPinSize && state.goodEnough) {
                    _submit(state.toString());
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
