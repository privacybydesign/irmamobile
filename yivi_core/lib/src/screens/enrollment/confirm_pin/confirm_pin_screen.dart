import "package:material_ui/material_ui.dart";

import "../../../widgets/bars/app_bar.dart";
import "../widgets/enrollment_bar.dart";
import "../../pin/pin_entry.dart";
import "../../pin/yivi_pin_screen.dart";

class ConfirmPinScreen extends StatelessWidget {
  static const String routeName = "confirm_pin";
  final StringCallback submitConfirmationPin;
  final VoidCallback onPrevious;
  final ValueNotifier<String> newPinNotifier;
  final String? stepLabel;

  /// Under the enrollment's own bar ([EnrollmentBar]), without a bar of its
  /// own.
  final bool underBar;
  final VoidCallback onPinMismatch;

  const ConfirmPinScreen({
    required this.submitConfirmationPin,
    required this.onPrevious,
    required this.newPinNotifier,
    this.stepLabel,
    this.underBar = false,
    required this.onPinMismatch,
  });

  @override
  Widget build(BuildContext context) {
    return YiviPinScaffold(
      // In the enrollment the bar over the steps has the back button: only
      // its room here.
      appBar: underBar
          ? PreferredSize(
              preferredSize: Size.fromHeight(EnrollmentBarSpace.of(context)),
              child: const SizedBox.shrink(),
            )
          : YiviAppBar(
              titleString: "",
              leading: YiviBackButton(onTap: onPrevious),
            ),
      body: PinEntry(
        mode: ConfirmEntry(
          chosen: newPinNotifier.value,
          instructionKey: "enrollment.confirm_pin.instruction",
          onMismatch: onPinMismatch,
          stepLabel: stepLabel,
        ),
        onSubmit: submitConfirmationPin,
      ),
    );
  }
}
