import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Builds the camera-preview widget that detects QR codes and reports the
/// payload string via [onCodeFound].
///
/// Each app target supplies its own implementation:
///   * yivi_app uses `mobile_scanner` (CameraX/ML Kit on Android, AVFoundation
///     on iOS).
///   * yivi_fdroid uses `flutter_zxing` (FFI to zxing-cpp, no Google ML Kit).
///
/// Contract:
///   * [onCodeFound] MAY be called repeatedly with the same code while a QR
///     remains in view; the caller (`QRScanner`) dedupes.
///   * Camera permission is assumed to be granted before this widget mounts
///     (gated in `handle_camera_permission.dart`).
///   * Implementations MUST restrict detection to QR codes only.
abstract class QrScannerFactory {
  const QrScannerFactory();

  Widget build({required void Function(String code) onCodeFound});
}

/// Overridden in `runYiviApp` with the target-specific implementation.
final qrScannerFactoryProvider = Provider<QrScannerFactory>(
  (_) => throw UnimplementedError(
    "qrScannerFactoryProvider must be overridden via runYiviApp(qrScannerFactory: ...)",
  ),
);
