import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../providers/irma_repository_provider.dart";
import "../widgets/irma_app_bar.dart";
import "pin/yivi_pin_screen.dart";

class YiviChoosePinScaffold extends StatelessWidget {
  final StringCallback submit;
  final VoidCallback onBack;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<String> newPinNotifier;

  YiviChoosePinScaffold({
    required this.submit,
    required this.onBack,
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
        titleString: "",
        leading: YiviBackButton(onTap: onBack),
        hasBorder: false,
      ),
      body: StreamBuilder<bool>(
        stream: prefs.getLongPin(),
        builder: (context, snapshot) {
          final toggleValue = ValueNotifier<bool>(
            newPinNotifier.value.isNotEmpty
                ? newPinNotifier.value.length > shortPinSize
                : (snapshot.data ?? false),
          );
          return ValueListenableBuilder<bool>(
            valueListenable: toggleValue,
            builder: (context, longPin, _) {
              final maxPinSize = longPin ? longPinSize : shortPinSize;
              final instructionKey =
                  'choose_pin.instruction.${longPin ? 'long' : 'short'}';
              return ProviderScope(
                overrides: [
                  enterPinProvider.overrideWith(() => EnterPinNotifier()),
                ],
                child: Consumer(
                  builder: (context, ref, _) {
                    ref.read(enterPinProvider.notifier).configure(maxPinSize);
                    return YiviPinScreen(
                      scaffoldKey: _scaffoldKey,
                      instructionKey: instructionKey,
                      maxPinSize: maxPinSize,
                      onSubmit: _submit,
                      onTogglePinSize: () =>
                          toggleValue.value = !toggleValue.value,
                      displayPinLength: true,
                      checkSecurePin: true,
                      listener: (context, state) {
                        if (maxPinSize == shortPinSize && state.goodEnough) {
                          _submit(state.toString());
                        }
                      },
                      submitButtonVisibilityListener: (context, state) {
                        if (!longPin && state.pin.length < shortPinSize) {
                          return defaultSubmitButtonVisibility(
                            context,
                            maxPinSize,
                          );
                        }
                        return WidgetVisibility.visible;
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
