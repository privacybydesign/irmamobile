import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/qr_scanner_factory_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../embedded_issuance_flows/documents/widgets/dark_glass.dart";

/// Where the scanner is: looking, read a Yivi QR code, or read another code.
enum ScanState { scanning, found, error }

const _foundTint = Color(0xD9176E40);
const _errorTint = Color(0xD9A01818);
const _white = Color(0xFFFFFFFF);

Color? _tint(ScanState state) => switch (state) {
  ScanState.found => _foundTint,
  ScanState.error => _errorTint,
  ScanState.scanning => null,
};

/// The instruction under the window of the upright scanner: one line in dark
/// glass, green or red after a code.
class ScanPill extends StatelessWidget {
  final ScanState state;

  const ScanPill({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final key = switch (state) {
      ScanState.scanning => "qr_scanner.instruction.message",
      ScanState.found => "qr_scanner.success.message",
      ScanState.error => "qr_scanner.error.message",
    };
    return Semantics(
      liveRegion: true,
      child: DarkGlass(
        key: const Key("qr_scanner_status"),
        tint: _tint(state),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state == ScanState.scanning) ...[
              const Icon(
                Icons.center_focus_weak_rounded,
                size: 18,
                color: _white,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                FlutterI18n.translate(context, key),
                textAlign: TextAlign.center,
                style: palette
                    .body(15, weight: FontWeight.w600)
                    .copyWith(color: _white, height: 20 / 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The left column of the sideways scanner: the title, what to do, where it
/// is, and the torch at the bottom.
class ScanSidePanel extends StatelessWidget {
  final ScanState state;
  final ScannerTorch torch;

  const ScanSidePanel({super.key, required this.state, required this.torch});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final status = switch (state) {
      ScanState.scanning => "qr_scanner.searching",
      ScanState.found => "qr_scanner.success.short",
      ScanState.error => "qr_scanner.error.message",
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Semantics(
            header: true,
            child: Text(
              FlutterI18n.translate(context, "qr_scanner.title"),
              style: palette.display(20).copyWith(color: _white),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          FlutterI18n.translate(context, "qr_scanner.instruction.side"),
          style: palette
              .body(14.5)
              .copyWith(color: const Color(0xD9FFFFFF), height: 21 / 14.5),
        ),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: DarkGlass(
            key: const Key("qr_scanner_status"),
            tint: _tint(state),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state == ScanState.scanning) ...[
                  const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _white,
                      backgroundColor: Color(0x4DFFFFFF),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    FlutterI18n.translate(context, status),
                    style: palette
                        .body(14, weight: FontWeight.w600)
                        .copyWith(color: _white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        TorchButton(torch: torch, size: 48, labelBeside: true),
      ],
    );
  }
}

/// The Zaklamp button: dark glass, white while the torch is on. Not shown
/// when the camera has no torch.
class TorchButton extends StatelessWidget {
  final ScannerTorch torch;
  final double size;

  /// The label to the right of the button (sideways) instead of under it.
  final bool labelBeside;

  const TorchButton({
    super.key,
    required this.torch,
    this.size = 56,
    this.labelBeside = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ListenableBuilder(
      listenable: torch,
      builder: (context, _) {
        if (!torch.available) return const SizedBox.shrink();
        final on = torch.on;
        final label = FlutterI18n.translate(
          context,
          on ? "qr_scanner.torch_on" : "qr_scanner.torch",
        );
        final icon = Icon(
          on ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
          size: size * 0.43,
          color: on ? const Color(0xFF1C1F23) : _white,
        );
        final button = SizedBox.square(
          dimension: size,
          child: on
              ? DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _white,
                  ),
                  child: Center(child: icon),
                )
              : DarkGlass(
                  shape: const CircleBorder(),
                  child: Center(child: icon),
                ),
        );
        final text = Text(
          label,
          style: labelBeside
              ? palette
                    .body(14, weight: FontWeight.w600)
                    .copyWith(color: _white)
              : palette.body(12.5).copyWith(color: const Color(0xBFFFFFFF)),
        );
        return Semantics(
          key: const Key("qr_scanner_torch"),
          button: true,
          toggled: on,
          label: FlutterI18n.translate(context, "qr_scanner.torch"),
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: torch.toggle,
            child: PressScale(
              scale: 0.94,
              child: labelBeside
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [button, const SizedBox(width: 12), text],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [button, const SizedBox(height: 6), text],
                    ),
            ),
          ),
        );
      },
    );
  }
}
