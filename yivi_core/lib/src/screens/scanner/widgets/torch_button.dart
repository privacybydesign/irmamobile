import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/qr_scanner_factory_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/press_scale.dart";

/// The Flashlight button, in the middle of the panel under the camera: a grey
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
