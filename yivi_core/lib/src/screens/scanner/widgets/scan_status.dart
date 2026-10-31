import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/qr_scanner_factory_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_surface.dart";

/// Where the scanner is: looking, read a Yivi QR code, or read another code.
enum ScanState { scanning, found, error }

/// The panel under the camera (beside it, sideways), on the sheet itself:
/// what the scanner says, and the torch. Upright one row, the torch at the
/// end; sideways a column, the torch at the bottom.
class ScanPanel extends StatelessWidget {
  final ScanState state;
  final ScannerTorch torch;
  final bool side;

  const ScanPanel({
    super.key,
    required this.state,
    required this.torch,
    this.side = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = ScanStatus(state: state);
    if (side) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          status,
          const Spacer(),
          TorchButton(torch: torch, labelBeside: true),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: status),
        const SizedBox(width: 16),
        TorchButton(torch: torch),
      ],
    );
  }
}

/// What the scanner says: the instruction while it looks, green or red
/// after a code, with an icon before it.
class ScanStatus extends StatelessWidget {
  final ScanState state;

  const ScanStatus({super.key, required this.state});

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
      child: Row(
        key: const Key("qr_scanner_status"),
        children: [
          Icon(icon, size: 26, color: colour),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              layoutBuilder: (current, previous) => Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [...previous, ?current],
              ),
              child: Text(
                FlutterI18n.translate(context, key),
                key: ValueKey(state),
                style: palette
                    .body(16, weight: FontWeight.w600)
                    .copyWith(color: colour, height: 21 / 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Zaklamp button: a grey disc, filled while the torch is on. Not shown
/// when the camera has no torch.
class TorchButton extends StatelessWidget {
  final ScannerTorch torch;

  /// The label to the right of the button (sideways) instead of under it.
  final bool labelBeside;

  const TorchButton({super.key, required this.torch, this.labelBeside = false});

  static const double size = 52;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ListenableBuilder(
      listenable: torch,
      builder: (context, _) {
        if (!torch.available) return const SizedBox.shrink();
        final on = torch.on;
        // One label, on or off: the fill says which (and the semantics),
        // so the instruction beside it keeps its room.
        final label = FlutterI18n.translate(context, "qr_scanner.torch");
        final button = AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on
                ? palette.text
                : palette.text.withValues(alpha: palette.isDark ? 0.14 : 0.07),
          ),
          child: Icon(
            on ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
            size: 24,
            color: on ? palette.sheet : palette.text,
          ),
        );
        final text = Text(
          label,
          style: labelBeside
              ? palette
                    .body(15, weight: FontWeight.w600)
                    .copyWith(color: palette.text)
              : palette.body(12).copyWith(color: palette.secondaryText),
        );
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
              child: labelBeside
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [button, const SizedBox(width: 12), text],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [button, const SizedBox(height: 4), text],
                    ),
            ),
          ),
        );
      },
    );
  }
}
