import "package:material_ui/material_ui.dart";

import "../../theme/yivi_tone.dart";
import "../../util/i18n.dart";
import "../../widgets/bars/action_bar.dart";
import "../../widgets/bars/irma_app_bar.dart";
import "../../widgets/feedback/status_screen.dart";

/// Shown when the user has used all transaction-code attempts on the
/// pre-authorized OpenID4VCI flow. Reuses the generic error scaffold but
/// substitutes the title/body with copy that explains the specific cause.
class TxCodeLockoutScreen extends StatelessWidget {
  final VoidCallback onTapClose;

  const TxCodeLockoutScreen({super.key, required this.onTapClose});

  @override
  Widget build(BuildContext context) {
    return StatusScreen(
      appBar: IrmaAppBar(
        titleTranslationKey: "error.details_title",
        leading: YiviBackButton(onTap: onTapClose),
      ),
      icon: Icons.lock_outline_rounded,
      tone: YiviTone.danger,
      title: context.tr("issuance.pre-authorized_code.tx_code_lockout.title"),
      message: context.tr("issuance.pre-authorized_code.tx_code_lockout.body"),
      actions: ActionBar.single(
        label: context.tr("error.button_ok"),
        onTap: onTapClose,
      ),
    );
  }
}
