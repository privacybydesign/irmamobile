import "dart:io";

import "package:smart_auth/smart_auth.dart";
import "package:yivi_core/yivi_core.dart";

import "ocr_processor.dart";
import "qr_scanner_factory.dart";
import "regula_face_service.dart";
import "sms_retriever.dart";
import "store_review_service.dart";

void main() => _run();

/// Entry point for the Activity that answers a Digital Credentials API request —
/// a browser calling `navigator.credentials.get()`, routed here by Android's
/// Credential Manager.
///
/// Named on the native side by `YiviDcApiActivity.getDartEntrypointFunctionName`,
/// and marked as an entry point so tree shaking keeps it: nothing in Dart calls
/// it, so to the compiler it is dead code.
///
/// The same app started somewhere else. The user did not open Yivi — a web page
/// asked Yivi a question — so it waits on the splash for that request instead of
/// loading the wallet, and the Activity closes it once the question is answered.
@pragma("vm:entry-point")
void dcApiMain() => _run(dcApiPresentation: true);

void _run({bool dcApiPresentation = false}) {
  runYiviApp(
    dcApiPresentation: dcApiPresentation,
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
