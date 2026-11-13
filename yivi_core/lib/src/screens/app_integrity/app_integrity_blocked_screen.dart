import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../widgets/irma_info_scaffold_body.dart";

/// Shown instead of the app while a debugger or an instrumentation tool is
/// attached to it. There is deliberately no way past it: the user closes the
/// tool and restarts the app.
class AppIntegrityBlockedScreen extends StatelessWidget {
  const AppIntegrityBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IrmaInfoScaffoldBody(
          imagePath: yiviAsset("error/insecure_device_illustration.svg"),
          titleTranslationKey: "app_integrity_blocked.title",
          bodyTranslationKey: "app_integrity_blocked.explanation",
        ),
      ),
    );
  }
}
