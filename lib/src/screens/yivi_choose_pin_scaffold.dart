import 'package:flutter/material.dart';

import '../widgets/irma_app_bar.dart';
import '../widgets/irma_repository_provider.dart';
import 'pin/yivi_pin_screen.dart';

class YiviChoosePinScaffold extends StatelessWidget {
  final StringCallback submit;
  final VoidCallback cancel;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final String instructionKey;

  YiviChoosePinScaffold({
    required this.submit,
    required this.cancel,
    required this.instructionKey,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = IrmaRepositoryProvider.of(context).preferences;

    return YiviPinScaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        title: '',
        leadingAction: cancel,
        leadingTooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      body: StreamBuilder<bool>(
        stream: prefs.getLongPin(),
        builder: (context, snapshot) {
          final toggleValue = ValueNotifier<bool>(snapshot.data ?? false);
          return ValueListenableBuilder<bool>(
            valueListenable: toggleValue,
            builder: (context, longPin, _) {
              final maxPinSize = longPin ? longPinSize : shortPinSize;
              final pinBloc = EnterPinStateBloc(maxPinSize);

              return YiviPinScreen(
                scaffoldKey: _scaffoldKey,
                instructionKey: instructionKey,
                maxPinSize: maxPinSize,
                onSubmit: submit,
                pinBloc: pinBloc,
                onTogglePinSize: () => toggleValue.value = !toggleValue.value,
                displayPinLength: true,
                checkSecurePin: true,
                listener: (context, state) {
                  if (maxPinSize == shortPinSize && state.goodEnough) {
                    submit(state.toString());
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
