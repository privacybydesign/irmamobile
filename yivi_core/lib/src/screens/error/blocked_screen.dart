import "package:material_ui/material_ui.dart";

import "../../models/clear_all_data_event.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/yivi_tone.dart";
import "../../util/i18n.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/status_screen.dart";

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Disable popping of this screen, as popping this is unwanted
    // (only way forward is and should be a reset, giving accidental access
    // to the wallet of a blocked account is unreasonable, even though credentials
    // can no longer be used)
    return PopScope(
      canPop: false,
      child: StatusScreen(
        appBar: IrmaAppBar(
          titleTranslationKey: "error.blocked_title",
          leading: null,
        ),
        icon: Icons.block_rounded,
        tone: YiviTone.danger,
        title: context.tr("error.blocked_title"),
        message: context.tr("error.types.blocked"),
        actions: IrmaBottomBar(
          primaryDanger: true,
          primaryButtonLabel: context.tr("error.button_reset"),
          onPrimaryPressed: () =>
              repositoryOf(context).bridgedDispatch(ClearAllDataEvent()),
        ),
      ),
    );
  }
}
