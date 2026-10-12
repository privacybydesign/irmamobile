import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_icon_button.dart";
import "../../../widgets/translated_text.dart";
import "success_graphic.dart";

const _graphicSize = 260.0;
const _closeIconSize = 22.0;
// 22 px icon plus this padding on both sides makes the 48 px touch target.
const _closePadding = 13.0;

/// Shown once the e-mail address is linked (`FeatureFlag.emailLinking`).
class EmailLinkedScreen extends StatelessWidget {
  final Function(BuildContext) onDismiss;

  const EmailLinkedScreen({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.backgroundTertiary,
        appBar: IrmaAppBar(
          titleTranslationKey: "email_linking.done.app_bar_title",
          hasBorder: false,
          leading: null,
          actions: [
            IrmaIconButton(
              icon: Icons.close,
              size: _closeIconSize,
              padding: const EdgeInsets.all(_closePadding),
              color: theme.dark,
              semanticsLabelKey: "accessibility.close",
              onTap: () => onDismiss(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: theme.largeSpacing,
            vertical: theme.largeSpacing + theme.defaultSpacing,
          ),
          child: Column(
            children: [
              const SizedBox.square(
                dimension: _graphicSize,
                child: SuccessGraphic(),
              ),
              SizedBox(height: theme.mediumSpacing),
              TranslatedText(
                "email_linking.done.title",
                isHeader: true,
                style: theme.textTheme.displayMedium,
              ),
              SizedBox(height: theme.mediumSpacing),
              TranslatedText(
                "email_linking.done.body",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        bottomNavigationBar: IrmaBottomBar(
          style: IrmaBottomBarStyle.flat,
          primaryButtonLabel: "action_feedback.ok",
          onPrimaryPressed: () => onDismiss(context),
        ),
      ),
    );
  }
}
