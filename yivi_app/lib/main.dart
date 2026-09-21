import "dart:io";

import "package:smart_auth/smart_auth.dart";
import "package:yivi_core/yivi_core.dart";

import "iris_runner.dart";
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
    // The face verification methods this build can run; the passport issuer
    // assigns one per document session from this declaration. Regula runs the
    // native SDK against the Face API the issuer announces at the start of
    // each session, so the same binary works against staging and production
    // without pinning either.
    faceVerificationRunners: (ref) => {
      FaceVerificationMethod.regula: RegulaRunner(
        (faceApiUrl) => RegulaFaceServiceImpl(serviceUrl: faceApiUrl),
      ),
      // Iris streams to whatever verifier the issuer names in its verify
      // response, so it needs no per-environment configuration either.
      FaceVerificationMethod.iris: IrisRunner(),
    },
    clientFlavor: Platform.isAndroid ? "play" : "appstore",
    storeReviewService: InAppReviewStoreReviewService(),
  );
}
