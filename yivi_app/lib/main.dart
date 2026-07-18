import "dart:io";

import "package:smart_auth/smart_auth.dart";
import "package:yivi_core/yivi_core.dart";

import "ocr_processor.dart";
import "qr_scanner_factory.dart";
import "regula_face_service.dart";
import "sms_retriever.dart";
import "store_review_service.dart";

void main() {
  runYiviApp(
    qrScannerFactory: MobileScannerQrFactory(),
    ocrProcessor: GoogleMLKitOcrProcessor(),
    smsRetriever: Platform.isAndroid
        ? SmartAuthSmsRetriever(SmartAuth.instance)
        : null,
    regulaFaceService: RegulaFaceServiceImpl(),
    storeReviewService: InAppReviewStoreReviewService(),
  );
}
