import "package:material_ui/material_ui.dart";

import "../../theme/yivi_tone.dart";
import "../../util/i18n.dart";
import "../../widgets/action_bar.dart";
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
      actions: ActionBar.single(
        key: const Key("warning_screen_accept_button"),
        label: context.tr("rooted_warning.accept_risk"),
        onTap: () => onAcceptRiskButtonPressed?.call(),
      ),
    );
  }
}
