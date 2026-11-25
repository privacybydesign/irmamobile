import "package:material_ui/material_ui.dart";

import "../../pin/pin_entry.dart";
import "../../pin/yivi_pin_screen.dart";
import "../widgets/enrollment_bar.dart";

/// Steps 3 and 4 on one page: choose a PIN, then enter the same again on the
/// same screen. Going on, the chosen PIN moves up out of the field, grey,
/// and a fresh field comes in under it with as many slots; a PIN that
/// doesn't match says so there and choosing starts over ([onMismatch]). The
/// PIN screen keeps every check of a secure PIN while choosing, and the
/// show-PIN eye keeps its setting.
class EnrollmentPinPage extends StatelessWidget {
  /// The PIN chosen, once it is entered again; null while choosing.
  final String? chosen;
  final ValueChanged<String> onChosen;
  final ValueChanged<String> onConfirmed;
  final VoidCallback onMismatch;

  const EnrollmentPinPage({
    super.key,
    required this.chosen,
    required this.onChosen,
    required this.onConfirmed,
    required this.onMismatch,
  });

  @override
  Widget build(BuildContext context) {
    final chosen = this.chosen;
    return YiviPinScaffold(
      // The bar over the steps has the back button: only its room here.
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(EnrollmentBarSpace.of(context)),
        child: const SizedBox.shrink(),
      ),
      body: PinEntry(
        mode: chosen == null
            ? const ChooseEntry()
            : ConfirmEntry(
                chosen: chosen,
                instructionKey: "choose_pin.again",
                onMismatch: onMismatch,
                inPlace: true,
              ),
        onSubmit: chosen == null ? onChosen : onConfirmed,
      ),
    );
  }
}
