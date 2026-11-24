import "package:material_ui/material_ui.dart";

import "../../theme/yivi_tone.dart";
import "../../util/i18n.dart";
import "../../widgets/bars/action_bar.dart";
import "../../widgets/feedback/status_screen.dart";

class RootedWarningScreen extends StatelessWidget {
  final VoidCallback? onAcceptRiskButtonPressed;

  /// What the risk is, in its own words: a rooted device, or an untrusted
  /// environment (see [DeviceRisk]).
  final String explanationTranslationKey;

  const RootedWarningScreen({
    super.key,
    this.onAcceptRiskButtonPressed,
    this.explanationTranslationKey = "rooted_warning.explanation",
  });

  @override
  Widget build(BuildContext context) {
    return StatusScreen(
      icon: Icons.gpp_maybe_rounded,
      tone: YiviTone.warning,
      title: context.tr("rooted_warning.title"),
      message: context.tr(explanationTranslationKey),
      actions: ActionBar.single(
        key: const Key("warning_screen_accept_button"),
        label: context.tr("rooted_warning.accept_risk"),
        onTap: () => onAcceptRiskButtonPressed?.call(),
      ),
    );
  }
}
