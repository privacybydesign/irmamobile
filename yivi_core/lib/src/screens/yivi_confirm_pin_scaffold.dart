import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../widgets/irma_app_bar.dart";
import "pin/yivi_pin_screen.dart";

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

    return YiviPinScaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        titleString: "",
        leading: YiviBackButton(onTap: onBack),
        hasBorder: false,
      ),
      body: ProviderScope(
        overrides: [enterPinProvider.overrideWith(() => EnterPinNotifier())],
        child: Consumer(
          builder: (context, ref, _) {
            ref.read(enterPinProvider.notifier).configure(maxPinSize);
            return YiviPinScreen(
              scaffoldKey: _scaffoldKey,
              instructionKey: instructionKey,
              maxPinSize: maxPinSize,
              onSubmit: _comparePins,
              listener: (context, state) {
                if (maxPinSize == shortPinSize &&
                    state.pin.length == maxPinSize) {
                  _comparePins(state.toString());
                }
              },
            );
          },
        ),
      ),
    );
  }
}
