import "package:flutter_i18n/flutter_i18n.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../util/missing_data_flow.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_dialog.dart";
import "../../../widgets/status_body.dart";
import "../../../widgets/yivi_themed_button.dart";
import "contact_widgets.dart";

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
      backgroundColor: palette.background,
      appBar: IrmaAppBar(
        bottom: context.missingDataBand,
        titleTranslationKey: titleTranslationKey,
        hasBorder: false,
      ),
      body: SafeArea(
        child: StatusBody(
          icon: Icons.error_outline_rounded,
          tone: DialogTone.danger,
          title: FlutterI18n.translate(context, contentTranslationKey),
          footer: ContactTextLink(
            labelKey: "error.button_show_error",
            onTap: () => _showIrmaDialog(context, errorMessage),
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "error.button_retry",
        secondaryButtonLabel: context.missingDataBackLabel(
          "email_issuance.enter_email.back_button",
        ),
        onPrimaryPressed: onTryAgain,
        onSecondaryPressed: context.missingDataBack(context.pop),
      ),
    );
  }

  Future _showIrmaDialog(BuildContext context, String content) async {
    await showDialog(
      context: context,
      builder: (context) {
        return IrmaDialog(
          title: FlutterI18n.translate(context, "error.details_title"),
          content: content,
          child: YiviThemedButton(
            label: "error.button_ok",
            onPressed: () => Navigator.of(context).pop(),
          ),
        );
      },
    );
  }
}
