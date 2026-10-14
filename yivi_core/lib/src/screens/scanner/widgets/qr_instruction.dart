import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/translated_text.dart";

/// The card above the scan window: a glass card with the instruction, which
/// turns green on success and red when the code is not a Yivi QR code.
class QRInstruction extends StatelessWidget {
  // QR code found
  final bool found;

  // wrong QR code found
  final bool error;

  const QRInstruction({required this.found, required this.error});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    final (screen, fill, textColor) = error
        ? ("error", const Color(0xE6BD1919), Colors.white)
        : found
        ? ("success", const Color(0xE6007A30), Colors.white)
        : ("instruction", null, palette.text);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: GlassSurface(
            shape: const RoundedSuperellipseBorder(
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            fill: fill,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TranslatedText(
                  "qr_scanner.$screen.title",
                  style: palette.display(18).copyWith(color: textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: TranslatedText(
                    "qr_scanner.$screen.message",
                    style: palette.body(16).copyWith(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
