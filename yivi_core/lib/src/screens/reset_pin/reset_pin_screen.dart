import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../theme/yivi_palette.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/translated_text.dart";
import "../settings/settings_screen.dart";

class ResetPinScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final small = MediaQuery.sizeOf(context).height < 670;
    final circle = small ? 150.0 : 200.0;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: IrmaAppBar(titleTranslationKey: "reset_pin.title"),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
                child: Column(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: circle,
                        height: circle,
                        padding: EdgeInsets.all(circle * 0.18),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: SvgPicture.asset(
                          yiviAsset("reset/forgot_pin_illustration.svg"),
                        ),
                      ),
                    ),
                    SizedBox(height: small ? 24 : 40),
                    TranslatedText(
                      "reset_pin.header",
                      isHeader: true,
                      textAlign: TextAlign.center,
                      style: palette
                          .display(26, weight: FontWeight.w700)
                          .copyWith(height: 36 / 26),
                    ),
                    const SizedBox(height: 8),
                    TranslatedText(
                      "reset_pin.explanation",
                      textAlign: TextAlign.center,
                      style: palette.body(16).copyWith(height: 24 / 16),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 4,
                children: [
                  PillButton(
                    key: const Key("reset_pin_reset"),
                    label: FlutterI18n.translate(context, "reset_pin.reset"),
                    style: PillStyle.dangerFilled,
                    height: 56,
                    onPressed: () => showConfirmDeleteDialog(context),
                  ),
                  PillButton(
                    key: const Key("reset_pin_cancel"),
                    label: FlutterI18n.translate(context, "ui.cancel"),
                    style: PillStyle.text,
                    height: 48,
                    // `Navigator.of(context).pop` (not GoRouter's
                    // `context.pop`) so this screen works whether it was
                    // pushed via the GoRouter `/reset_pin` route or onto the
                    // LockGate overlay's local Navigator.
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
