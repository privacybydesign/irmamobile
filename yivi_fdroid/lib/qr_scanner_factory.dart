import "package:flutter/widgets.dart";
import "package:flutter_zxing/flutter_zxing.dart";
import "package:yivi_core/yivi_core.dart";

/// QR scanner backed by `flutter_zxing` (FFI bindings to zxing-cpp via
/// `package:camera`). No ML Kit, no Play Services, no SurfaceView-based
/// PlatformView — keeps yivi_fdroid free of non-FOSS dependencies while
/// remaining Impeller-compatible.
class FlutterZxingQrFactory implements QrScannerFactory {
  @override
  Widget build({required void Function(String code) onCodeFound}) {
    return ReaderWidget(
      codeFormat: Format.qrCode,
      onScan: (result) {
        final text = result.text;
        if (text != null && text.isNotEmpty) onCodeFound(text);
      },
      // yivi_core's QROverlay draws the framing/instruction chrome.
      showScannerOverlay: false,
      showFlashlight: false,
      showGallery: false,
    );
  }
}
