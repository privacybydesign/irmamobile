import "package:yivi_core/yivi_core.dart";

import "ocr_processor.dart";
import "qr_scanner_factory.dart";

void main() {
  runYiviApp(
    qrScannerFactory: const FlutterZxingQrFactory(),
    ocrProcessor: TesseractOcrProcessor(),
  );
}
