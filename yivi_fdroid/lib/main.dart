import "package:yivi_core/yivi_core.dart";
import "ocr_processor.dart";
import "qr_scanner_factory.dart";
import "regula_web_face_service.dart";

void main() {
  runYiviApp(
    qrScannerFactory: FlutterZxingQrFactory(),
    ocrProcessor: TesseractOcrProcessor(),
    // FOSS liveness via Regula's web Face SDK in an embedded WebView; no
    // proprietary native binaries ship in the F-Droid APK (see #665).
    regulaFaceService: RegulaWebFaceService(),
  );
}
