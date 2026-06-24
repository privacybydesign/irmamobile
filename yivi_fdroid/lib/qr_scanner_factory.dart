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
      // Decode the whole frame, not ReaderWidget's default centered 50% square.
      // A large QR code filling the viewport has its finder patterns cropped
      // out by the default 0.5, so it never decodes. 1.0 matches the area of
      // yivi_core's QROverlay scan window.
      cropPercent: 1.0,
      // tryDownscale lets zxing-cpp decode codes whose modules are large
      // relative to the image (i.e. big/close codes); tryHarder spends more
      // effort on dense ones. scanDelay is 1s so the extra cost is negligible.
      tryHarder: true,
      tryDownscale: true,
      // yivi_core's QROverlay draws the framing/instruction chrome.
      showScannerOverlay: false,
      showFlashlight: false,
      showGallery: false,
      showToggleCamera: false,
    );
  }
}
