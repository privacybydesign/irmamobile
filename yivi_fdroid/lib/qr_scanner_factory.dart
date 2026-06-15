import "package:flutter/widgets.dart";
import "package:flutter_zxing/flutter_zxing.dart";
import "package:yivi_core/yivi_core.dart";

/// QR scanner backed by `flutter_zxing` (FFI to zxing-cpp).
///
/// FOSS alternative to `mobile_scanner` — no Google ML Kit, no Play Services
/// dependency. Renders via `package:camera` (TextureView on Android), so the
/// preview composites correctly with Impeller.
class FlutterZxingQrFactory extends QrScannerFactory {
  const FlutterZxingQrFactory();

  @override
  Widget build({required void Function(String code) onCodeFound}) {
    return ReaderWidget(
      codeFormat: Format.qrCode,
      // yivi_core's QROverlay/QRInstruction render the UI affordances; the
      // scanner widget should be camera-preview only.
      showScannerOverlay: false,
      showFlashlight: false,
      showToggleCamera: false,
      showGallery: false,
      onScan: (code) {
        final text = code.text;
        if (text != null && text.isNotEmpty) {
          onCodeFound(text);
        }
      },
    );
  }
}
