import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../providers/irma_repository_provider.dart";
import "../widgets/irma_app_bar.dart";
import "pin/yivi_pin_screen.dart";

class YiviChoosePinScaffold extends StatelessWidget {
  final StringCallback submit;
  final VoidCallback onBack;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<String> newPinNotifier;

  /// "Step 1 of 3" above the title, while enrolling.
  final String? stepLabel;

  YiviChoosePinScaffold({
    required this.submit,
    required this.onBack,
    required this.newPinNotifier,
    this.stepLabel,
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
              return YiviPinScreen(
                scaffoldKey: _scaffoldKey,
                lockIcon: true,
                stepLabel: stepLabel,
                instructionKey: instructionKey,
                maxPinSize: maxPinSize,
                onSubmit: _submit,
                onTogglePinSize: () => toggleValue.value = !toggleValue.value,
                // A long PIN's rule; a PIN that is possibly not secure says
                // so in this line instead (checkSecurePin).
                detail: longPin
                    ? FlutterI18n.translate(context, "choose_pin.long_rule")
                    : null,
                checkSecurePin: true,
                // A secure short PIN goes on by itself; one that is possibly
                // not secure, and a long PIN, by the arrow.
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
