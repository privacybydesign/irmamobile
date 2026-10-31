import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../pin/yivi_pin_screen.dart";
import "../../yivi_basic_pin_scaffold.dart";
import "../models/validation_state.dart";
import "../providers/change_pin_providers.dart";

class EnterPin extends ConsumerWidget {
  static const String routeName = "change_pin/enter_pin";

  final void Function(String) submitOldPin;
  final VoidCallback? cancel;

  const EnterPin({required this.submitOldPin, this.cancel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // After a wrong PIN this page is opened again, saying so: the tries left.
    final verification = ref.watch(verifyOldPinProvider);
    return YiviBasicPinScaffold(
      submit: submitOldPin,
      cancel: cancel,
      instructionKey: "change_pin.enter_pin.instruction",
      error: pinAttemptLine(
        context,
        wrong: verification.validationState == ValidationState.invalid,
        left: verification.attemptsRemaining,
      ),
    );
  }
}
