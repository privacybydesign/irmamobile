import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../theme/yivi_palette.dart";
import "../../widgets/centred_max_width.dart";
import "../../widgets/glass/floating_bar_placement.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/translated_text.dart";
import "../settings/settings_screen.dart";

class ResetPinScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final size = MediaQuery.sizeOf(context);
    // Wider than high: the picture on the left, the text and the buttons on
    // the right.
    final sideways = size.width > size.height && size.width >= 560;
    final small = size.height < 670;
    final circle = small ? 150.0 : 200.0;

    final picture = ExcludeSemantics(
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
        child: SvgPicture.asset(yiviAsset("reset/forgot_pin_illustration.svg")),
      ),
    );
    final align = sideways ? TextAlign.start : TextAlign.center;
    final texts = [
      TranslatedText(
        "reset_pin.header",
        isHeader: true,
        textAlign: align,
        style: palette
            .display(26, weight: FontWeight.w700)
            .copyWith(height: 36 / 26),
      ),
      const SizedBox(height: 8),
      TranslatedText(
        "reset_pin.explanation",
        textAlign: align,
        style: palette.body(16).copyWith(height: 24 / 16),
      ),
    ];
    final buttons = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        PillButton(
          key: const Key("reset_pin_reset"),
          label: FlutterI18n.translate(context, "reset_pin.reset"),
          style: PillStyle.dangerFilled,
          size: PillSize.large,
          onPressed: () => showConfirmDeleteDialog(context),
        ),
        PillButton(
          key: const Key("reset_pin_cancel"),
          label: FlutterI18n.translate(context, "ui.cancel"),
          style: PillStyle.text,
          size: PillSize.large,
          // `Navigator.of(context).pop` (not GoRouter's
          // `context.pop`) so this screen works whether it was
          // pushed via the GoRouter `/reset_pin` route or onto the
          // LockGate overlay's local Navigator.
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: palette.background,
      appBar: IrmaAppBar(titleTranslationKey: "reset_pin.title"),
      // Clear of the notch, the Dynamic Island or a side panel at the sides.
      body: SafeArea(
        top: false,
        bottom: false,
        child: sideways
            ? _sideways(context, picture, texts, buttons)
            : _upright(context, picture, texts, buttons, small),
      ),
    );
  }

  Widget _upright(
    BuildContext context,
    Widget picture,
    List<Widget> texts,
    Widget buttons,
    bool small,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
            child: SafeArea(
              child: Column(
                children: [
                  picture,
                  SizedBox(height: small ? 24 : 40),
                  ...texts,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            FloatingBarPlacement.buttonBottom(context),
          ),
          child: buttons,
        ),
      ],
    );
  }

  Widget _sideways(
    BuildContext context,
    Widget picture,
    List<Widget> texts,
    Widget buttons,
  ) {
    final padding = MediaQuery.paddingOf(context);
    return CentredMaxWidth(
      maxWidth: 1000,
      child: Row(
        spacing: 48,
        children: [
          Expanded(child: Center(child: picture)),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                0,
                padding.top + 16,
                16,
                FloatingBarPlacement.buttonBottom(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [...texts, const SizedBox(height: 24), buttons],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
