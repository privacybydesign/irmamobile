import "package:yivi/ocr_processor.dart";
import "package:yivi_core/src/testing/helpers/helpers.dart";

void configureSharedIntegrationTest() {
  configureTestOcrProcessor(TesseractOcrProcessor());
}
