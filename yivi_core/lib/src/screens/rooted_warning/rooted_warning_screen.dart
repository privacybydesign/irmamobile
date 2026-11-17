import "package:material_ui/material_ui.dart";

import "../../theme/yivi_tone.dart";
import "../../util/i18n.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/status_screen.dart";

class RootedWarningScreen extends StatelessWidget {
  final VoidCallback? onAcceptRiskButtonPressed;

  const RootedWarningScreen({this.onAcceptRiskButtonPressed});

  @override
  Widget build(BuildContext context) {
    return StatusScreen(
      icon: Icons.gpp_maybe_rounded,
      tone: YiviTone.warning,
      title: context.tr("rooted_warning.title"),
      message: context.tr("rooted_warning.explanation"),
      actions: IrmaBottomBar(
        key: const Key("warning_screen_accept_button"),
        primaryButtonLabel: context.tr("rooted_warning.accept_risk"),
        onPrimaryPressed: () => onAcceptRiskButtonPressed?.call(),
      ),
    );
  }
}
