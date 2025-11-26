import "package:yivi_core/yivi_core.dart";

import "ocr_processor.dart";

void main() {
  runYiviApp(ocrProcessor: GoogleMLKitMrzProcessor());
}
