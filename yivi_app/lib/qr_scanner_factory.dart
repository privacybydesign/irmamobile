import "package:flutter/widgets.dart";
import "package:mobile_scanner/mobile_scanner.dart";
import "package:yivi_core/yivi_core.dart";

/// QR scanner backed by `mobile_scanner`.
///
/// Uses CameraX + bundled ML Kit on Android (no Play Services dependency) and
/// AVFoundation on iOS. Renders the camera preview into a Flutter texture, so
/// it composites correctly with Impeller.
class MobileScannerQrFactory extends QrScannerFactory {
  const MobileScannerQrFactory();

  @override
  Widget build({required void Function(String code) onCodeFound}) {
    return _MobileScannerView(onCodeFound: onCodeFound);
  }
}

/// Owns the [MobileScannerController] lifecycle for a single scanner mount.
class _MobileScannerView extends StatefulWidget {
  final void Function(String code) onCodeFound;

  const _MobileScannerView({required this.onCodeFound});

  @override
  State<_MobileScannerView> createState() => _MobileScannerViewState();
}

class _MobileScannerViewState extends State<_MobileScannerView> {
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        widget.onCodeFound(raw);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(controller: _controller, onDetect: _handleDetection);
  }
}
