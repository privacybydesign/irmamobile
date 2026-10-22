import "dart:async";

import "package:flutter/widgets.dart";
import "package:mobile_scanner/mobile_scanner.dart";
import "package:yivi_core/yivi_core.dart";

/// QR scanner backed by `mobile_scanner` (CameraX + bundled ML Kit on
/// Android, AVFoundation on iOS). Renders into a Flutter texture rather than
/// a SurfaceView-based PlatformView, so Impeller can composite it.
class MobileScannerQrFactory implements QrScannerFactory {
  @override
  Widget build({
    required void Function(String code) onCodeFound,
    required ScannerTorch torch,
  }) => _Scanner(onCodeFound: onCodeFound, torch: torch);
}

class _Scanner extends StatefulWidget {
  final void Function(String code) onCodeFound;
  final ScannerTorch torch;

  const _Scanner({required this.onCodeFound, required this.torch});

  @override
  State<_Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<_Scanner> {
  // Owned here, so the torch can be switched and the camera is released
  // with the scanner (MobileScanner stops a controller it is given, but
  // leaves disposing it to its owner).
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    // Pin to the standard 1x back camera. The default (CameraLensType.any)
    // lets iOS pick the virtual builtInTripleCamera, whose default zoom
    // maps to the ultra-wide (0.5x) constituent lens. Note the naming trap:
    // `normal` is the wide-angle 1x lens; `wide` is the ultra-wide one.
    lensType: CameraLensType.normal,
  );

  @override
  void initState() {
    super.initState();
    widget.torch.connect(() => unawaited(_controller.toggleTorch()));
    _controller.addListener(_reportTorch);
  }

  void _reportTorch() {
    final state = _controller.value.torchState;
    widget.torch.report(
      available: state != TorchState.unavailable,
      on: state == TorchState.on,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_reportTorch);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: (capture) {
        final raw = capture.barcodes.firstOrNull?.rawValue;
        if (raw != null) widget.onCodeFound(raw);
      },
    );
  }
}
