import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Builds the camera-preview widget that detects QR codes and reports the
/// payload string via [onCodeFound].
///
/// Contract:
///   - [onCodeFound] MAY be called repeatedly with the same code while a QR
///     remains in view. The caller (QRScanner) dedupes.
///   - The widget assumes camera permission has already been granted. The
///     caller (yivi_core's handle_camera_permission.dart) gates this.
///   - The widget MUST restrict detection to QR codes only — no other
///     barcode formats are valid IRMA pointers.
///   - Each call to [build] returns a fresh widget; controllers/streams
///     are owned by that widget.
abstract class QrScannerFactory {
  Widget build({required void Function(String code) onCodeFound});
}

final qrScannerFactoryProvider = Provider<QrScannerFactory>(
  (_) => throw UnimplementedError(
    "qrScannerFactoryProvider must be overridden via runYiviApp(qrScannerFactory: ...)",
  ),
);
