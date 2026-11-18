import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../theme/yivi_palette.dart";
import "../../util/i18n.dart";
import "../../widgets/bars/action_bar.dart";
import "../../widgets/bars/irma_app_bar.dart";
import "../../widgets/feedback/status_screen.dart";
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
      actions: ActionBar(
        actions: [
          ActionBar.primary(
            label: context.tr("reset_pin.reset"),
            onTap: () => showConfirmDeleteDialog(context),
            danger: true,
          ),
          ActionBar.secondary(
            label: context.tr("ui.cancel"),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
