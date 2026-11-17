import "package:material_ui/material_ui.dart";

import "../../theme/yivi_tone.dart";
import "../../util/i18n.dart";
import "../../widgets/action_bar.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/status_screen.dart";

class NoInternetScreen extends StatelessWidget {
  final VoidCallback onTapClose;
  final VoidCallback? onTapRetry;

  const NoInternetScreen({required this.onTapClose, this.onTapRetry})
    : super(key: const ValueKey("no_internet_screen"));

  @override
  Widget build(BuildContext context) {
    return StatusScreen(
      appBar: IrmaAppBar(
        titleTranslationKey: "error.details_title",
        leading: YiviBackButton(onTap: onTapClose),
      ),
      icon: Icons.wifi_off_rounded,
      tone: YiviTone.info,
      title: context.tr("error.no_internet_title"),
      message: context.tr("error.types.no_internet"),
      actions: ActionBar(
        actions: [
          ActionBar.primary(
            label: context.tr("error.button_back"),
            onTap: onTapClose,
          ),
          if (onTapRetry != null)
            ActionBar.secondary(
              label: context.tr("error.button_retry"),
              onTap: onTapRetry,
            ),
        ],
      ),
    );
  }
}
