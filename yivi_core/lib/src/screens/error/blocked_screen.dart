import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../models/clear_all_data_event.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/irma_info_scaffold_body.dart";

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
      child: Scaffold(
        backgroundColor: YiviPalette.of(context).background,
        appBar: IrmaAppBar(
          titleTranslationKey: "error.blocked_title",
          leading: null,
        ),
        body: IrmaInfoScaffoldBody(
          icon: Icons.block_rounded,
          tone: DialogTone.danger,
          titleTranslationKey: "error.blocked_title",
          bodyTranslationKey: "error.types.blocked",
        ),
        bottomNavigationBar: IrmaBottomBar(
          primaryDanger: true,
          primaryButtonLabel: FlutterI18n.translate(
            context,
            "error.button_reset",
          ),
          onPrimaryPressed: () => IrmaRepositoryProvider.of(
            context,
          ).bridgedDispatch(ClearAllDataEvent()),
        ),
      ),
    );
  }
}
