import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/irma_info_scaffold_body.dart";

class RootedWarningScreen extends StatelessWidget {
  final VoidCallback? onAcceptRiskButtonPressed;

  const RootedWarningScreen({this.onAcceptRiskButtonPressed});

  @override
  Widget build(BuildContext context) {
    return IrmaInfoScreen(
      icon: Icons.gpp_maybe_rounded,
      tone: DialogTone.warning,
      titleTranslationKey: "rooted_warning.title",
      bodyTranslationKey: "rooted_warning.explanation",
      bottomBar: IrmaBottomBar(
        key: const Key("warning_screen_accept_button"),
        primaryButtonLabel: FlutterI18n.translate(
          context,
          "rooted_warning.accept_risk",
        ),
        onPrimaryPressed: () => onAcceptRiskButtonPressed?.call(),
      ),
    );
  }
}
