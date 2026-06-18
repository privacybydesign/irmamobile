import "package:flutter/widgets.dart";
import "package:mobile_scanner/mobile_scanner.dart";
import "package:yivi_core/yivi_core.dart";

/// QR scanner backed by `mobile_scanner` (CameraX + bundled ML Kit on
/// Android, AVFoundation on iOS). Renders into a Flutter texture rather than
/// a SurfaceView-based PlatformView, so Impeller can composite it.
class MobileScannerQrFactory implements QrScannerFactory {
  @override
  Widget build({required void Function(String code) onCodeFound}) {
    return MobileScanner(
      controller: MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
      ),
      onDetect: (capture) {
        final raw = capture.barcodes.firstOrNull?.rawValue;
        if (raw != null) onCodeFound(raw);
      },
    );
  }
}
