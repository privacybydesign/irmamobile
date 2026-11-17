import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../widgets/irma_app_bar.dart";
import "../../pin/pin_entry.dart";
import "../../pin/pin_feedback.dart";
import "../../pin/yivi_pin_screen.dart";
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
    return YiviPinScaffold(
      appBar: IrmaAppBar(
        titleString: "",
        leading: YiviBackButton(
          onTap: cancel != null
              ? () async {
                  cancel?.call();
                  if (!await Navigator.of(context).maybePop()) {
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  }
                }
              : null,
        ),
      ),
      body: PinEntry(
        mode: const VerifyOldEntry(),
        feedback: PinFeedback(
          wrong: verification.validationState == ValidationState.invalid,
          left: verification.attemptsRemaining,
        ),
        onSubmit: submitOldPin,
      ),
    );
  }
}
