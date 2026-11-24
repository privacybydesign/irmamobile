import "package:material_ui/material_ui.dart";

import "../../theme/yivi_tone.dart";
import "../../util/i18n.dart";
import "../../widgets/feedback/status_screen.dart";

/// Shown instead of the app while a debugger or an instrumentation tool is
/// attached to it. There is deliberately no way past it: the user closes the
/// tool and restarts the app.
class AppIntegrityBlockedScreen extends StatelessWidget {
  const AppIntegrityBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: StatusScreen(
        key: const Key("app_integrity_blocked"),
        icon: Icons.gpp_bad_rounded,
        tone: YiviTone.danger,
        title: context.tr("app_integrity_blocked.title"),
        message: context.tr("app_integrity_blocked.explanation"),
      ),
    );
  }
}
