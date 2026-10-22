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
    // The native SDK runs liveness against the Face API the passport issuer
    // announces at the start of each document session, so the same binary
    // works against staging and production without pinning either. No
    // announcement (issuer disables face verification, or no document flow
    // yet) → no service.
    regulaFaceService: (ref) {
      final config = ref.watch(faceVerificationConfigProvider);
      return config == null
          ? null
          : RegulaFaceServiceImpl(serviceUrl: config.faceApiUrl);
    },
    storeReviewService: InAppReviewStoreReviewService(),
  );
}
