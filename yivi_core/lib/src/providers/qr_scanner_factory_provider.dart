import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Builds the camera-preview widget that detects QR codes and reports the
/// payload string via [onCodeFound].
///
/// Contract:
///   - [onCodeFound] MAY be called repeatedly with the same code while a QR
///     remains in view. The caller (QRScanner) dedupes.
///   - The widget assumes camera permission has already been granted. The
///     caller (yivi_core's ScannerScreen) gates this.
///   - The widget MUST restrict detection to QR codes only — no other
///     barcode formats are valid IRMA pointers.
///   - Each call to [build] returns a fresh widget; controllers/streams
///     are owned by that widget.
///   - The widget connects [torch] to its camera ([ScannerTorch.connect])
///     and reports whether it has one and whether it is on. The torch goes
///     out with the widget.
abstract class QrScannerFactory {
  Widget build({
    required void Function(String code) onCodeFound,
    required ScannerTorch torch,
  });
}

/// The camera's torch, as the scanner shows it (the Zaklamp button): whether
/// the camera has one, whether it is on, and a way to switch it.
class ScannerTorch extends ChangeNotifier {
  bool _available = false;
  bool _on = false;
  VoidCallback? _toggle;

  /// Whether the camera has a torch; the button is hidden without one.
  bool get available => _available;

  bool get on => _on;

  /// Called by the camera widget once its camera is ready.
  void connect(VoidCallback toggle) => _toggle = toggle;

  /// Called by the camera widget whenever the torch changes.
  void report({required bool available, bool on = false}) {
    if (available == _available && on == _on) return;
    _available = available;
    _on = available && on;
    notifyListeners();
  }

  void toggle() => _toggle?.call();
}

final qrScannerFactoryProvider = Provider<QrScannerFactory>(
  (_) => throw UnimplementedError(
    "qrScannerFactoryProvider must be overridden via runYiviApp(qrScannerFactory: ...)",
  ),
);
