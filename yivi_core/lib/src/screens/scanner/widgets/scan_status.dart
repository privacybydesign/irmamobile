import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/qr_scanner_factory_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_surface.dart";

/// Where the scanner is: looking, read a Yivi QR code, or read another code.
enum ScanState { scanning, found, error }

/// What the scanner says, as a pill on the camera under the window: white
/// (black in the dark theme), the instruction while it looks, green or red
/// after a code, with an icon before it.
class ScanPill extends StatelessWidget {
  final ScanState state;

  const ScanPill({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final (key, icon, colour) = switch (state) {
      ScanState.scanning => (
        "qr_scanner.instruction.message",
        CupertinoIcons.qrcode_viewfinder,
        palette.text,
      ),
      ScanState.found => (
        "qr_scanner.success.message",
        CupertinoIcons.checkmark_circle_fill,
        palette.successText,
      ),
      ScanState.error => (
        "qr_scanner.error.message",
        CupertinoIcons.xmark_circle_fill,
        palette.errorText,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        key: const Key("qr_scanner_status"),
        decoration: BoxDecoration(
          color: palette.isDark ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: palette.isDark ? 0.35 : 0.22,
              ),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: colour),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    FlutterI18n.translate(context, key),
                    textAlign: TextAlign.center,
                    style: palette
                        .body(14.5, weight: FontWeight.w600)
                        .copyWith(color: colour, height: 20 / 14.5),
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

/// The Zaklamp button, in the middle of the panel under the camera: a grey
/// disc, filled while the torch is on, its label under it. Not shown when
/// the camera has no torch.
class TorchButton extends StatelessWidget {
  final ScannerTorch torch;

  const TorchButton({super.key, required this.torch});

  static const double size = 56;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ListenableBuilder(
      listenable: torch,
      builder: (context, _) {
        if (!torch.available) return const SizedBox.shrink();
        final on = torch.on;
        // One label, on or off: the fill says which (and the semantics).
        final label = FlutterI18n.translate(context, "qr_scanner.torch");
        return Semantics(
          key: const Key("qr_scanner_torch"),
          button: true,
          toggled: on,
          label: label,
          excludeSemantics: true,
          onTap: torch.toggle,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: torch.toggle,
            child: PressScale(
              scale: PressScale.button,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on
                          ? palette.text
                          : palette.text.withValues(
                              alpha: palette.isDark ? 0.14 : 0.07,
                            ),
                    ),
                    child: Icon(
                      on
                          ? Icons.flashlight_on_rounded
                          : Icons.flashlight_off_rounded,
                      size: 24,
                      color: on ? palette.sheet : palette.text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: palette
                        .body(12)
                        .copyWith(color: palette.secondaryText),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
