import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../theme/yivi_palette.dart";
import "../../util/i18n.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/status_screen.dart";
import "../settings/settings_screen.dart";

/// Forgot your PIN: the only way on is to delete everything and start
/// again.
class ResetPinScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StatusScreen(
      appBar: IrmaAppBar(titleTranslationKey: "reset_pin.title"),
      discColor: YiviPalette.of(context).surface,
      picture: Padding(
        padding: const EdgeInsets.all(26),
        child: SvgPicture.asset(yiviAsset("reset/forgot_pin_illustration.svg")),
      ),
      title: context.tr("reset_pin.header"),
      message: context.tr("reset_pin.explanation"),
      actions: IrmaBottomBar(
        primaryDanger: true,
        primaryButtonLabel: "reset_pin.reset",
        onPrimaryPressed: () => showConfirmDeleteDialog(context),
        secondaryButtonLabel: "ui.cancel",
        // `Navigator.of(context).pop` (not GoRouter's `context.pop`) so this
        // screen works whether it was pushed via the GoRouter `/reset_pin`
        // route or onto the LockGate overlay's local Navigator.
        onSecondaryPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
