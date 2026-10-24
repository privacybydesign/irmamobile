import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/irma_info_scaffold_body.dart";

/// Shown when the user has used all transaction-code attempts on the
/// pre-authorized OpenID4VCI flow. Reuses the generic error scaffold but
/// substitutes the title/body with copy that explains the specific cause.
class TxCodeLockoutScreen extends StatelessWidget {
  final VoidCallback onTapClose;

  const TxCodeLockoutScreen({super.key, required this.onTapClose});

  @override
  Widget build(BuildContext context) {
    return IrmaInfoScreen(
      appBar: IrmaAppBar(
        titleTranslationKey: "error.details_title",
        leading: YiviBackButton(onTap: onTapClose),
      ),
      icon: Icons.lock_outline_rounded,
      tone: DialogTone.danger,
      titleTranslationKey: "issuance.pre-authorized_code.tx_code_lockout.title",
      bodyTranslationKey: "issuance.pre-authorized_code.tx_code_lockout.body",
      bottomBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, "error.button_ok"),
        onPrimaryPressed: onTapClose,
      ),
    );
  }
}
