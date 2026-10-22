import "package:camera/camera.dart";
import "package:flutter/widgets.dart";
import "package:flutter_zxing/flutter_zxing.dart";
import "package:yivi_core/yivi_core.dart";

/// QR scanner backed by `flutter_zxing` (FFI bindings to zxing-cpp via
/// `package:camera`). No ML Kit, no Play Services, no SurfaceView-based
/// PlatformView — keeps yivi_fdroid free of non-FOSS dependencies while
/// remaining Impeller-compatible.
class FlutterZxingQrFactory implements QrScannerFactory {
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
  /// The camera ReaderWidget made; it makes a new one when the app comes
  /// back to the front, and disposes it itself.
  CameraController? _camera;
  bool _on = false;

  @override
  void initState() {
    super.initState();
    widget.torch.connect(_toggle);
  }

  void _onCamera(CameraController? camera, Exception? error) {
    _camera = camera;
    _on = false;
    widget.torch.report(available: camera != null);
  }

  Future<void> _toggle() async {
    final camera = _camera;
    if (camera == null) return;
    try {
      await camera.setFlashMode(_on ? FlashMode.off : FlashMode.torch);
      _on = !_on;
      if (mounted) widget.torch.report(available: true, on: _on);
    } on CameraException {
      // A camera without a torch: hide the button.
      if (mounted) widget.torch.report(available: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReaderWidget(
      codeFormat: Format.qrCode,
      onScan: (result) {
        final text = result.text;
        if (text != null && text.isNotEmpty) widget.onCodeFound(text);
      },
      onControllerCreated: _onCamera,
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
      // yivi_core's QROverlay draws the framing/instruction chrome, and its
      // scanner the torch button.
      showScannerOverlay: false,
      showFlashlight: false,
      showGallery: false,
      showToggleCamera: false,
    );
  }
}
