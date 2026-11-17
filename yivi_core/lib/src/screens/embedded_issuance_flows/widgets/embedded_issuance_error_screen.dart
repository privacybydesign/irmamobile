import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_tone.dart";
import "../../../util/i18n.dart";
import "../../../widgets/error_status_screen.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/status_body.dart";

class EmbeddedIssuanceErrorScreen extends StatelessWidget {
  const EmbeddedIssuanceErrorScreen({
    super.key,
    required this.titleTranslationKey,
    required this.contentTranslationKey,
    required this.errorMessage,
    required this.onTryAgain,
  });

  final String titleTranslationKey;
  final String contentTranslationKey;
  final String errorMessage;
  final Function() onTryAgain;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: palette.background,
      appBar: IrmaAppBar(titleTranslationKey: titleTranslationKey),
      body: StatusBody(
        icon: Icons.error_outline_rounded,
        tone: YiviTone.danger,
        title: context.tr(contentTranslationKey),
        footer: ErrorDetails(details: errorMessage),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "error.button_retry",
        secondaryButtonLabel: "email_issuance.enter_email.back_button",
        onPrimaryPressed: onTryAgain,
        onSecondaryPressed: context.pop,
      ),
    );
  }
}
