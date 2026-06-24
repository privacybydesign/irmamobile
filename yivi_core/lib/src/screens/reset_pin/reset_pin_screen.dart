import "package:flutter/material.dart";

import "package:flutter_svg/svg.dart";

import "../../../package_name.dart";
import "../../theme/theme.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/yivi_themed_button.dart";
import "../session/widgets/dynamic_layout.dart";
import "../settings/settings_screen.dart";

class ResetPinScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.height < 670;

    return Scaffold(
      appBar: IrmaAppBar(titleTranslationKey: "reset_pin.title"),
      body: DynamicLayout(
        hero: SvgPicture.asset(
          yiviAsset("reset/forgot_pin_illustration.svg"),
          height: isSmallScreen ? 250 : null,
        ),
        content: Column(
          children: [
            TranslatedText(
              "reset_pin.header",
              style: context.text.headlineSmall,
            ),
            SizedBox(height: context.yivi.spacing.tiny),
            TranslatedText(
              "reset_pin.explanation",
              style: context.text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          YiviThemedButton(
            style: YiviButtonStyle.outlined,
            label: "ui.cancel",
            // `Navigator.of(context).pop` (not GoRouter's
            // `context.pop`) so this screen works whether it was
            // pushed via the GoRouter `/reset_pin` route or onto the
            // LockGate overlay's local Navigator.
            onPressed: () => Navigator.of(context).pop(),
          ),
          YiviThemedButton(
            label: "reset_pin.reset",
            onPressed: () => showConfirmDeleteDialog(context),
          ),
        ],
      ),
    );
  }
}
