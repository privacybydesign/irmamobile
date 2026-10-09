import "package:yivi_core/yivi_core.dart";
import "ocr_processor.dart";
import "qr_scanner_factory.dart";
import "regula_web_face_service.dart";

void main() {
  runYiviApp(
    qrScannerFactory: FlutterZxingQrFactory(),
    ocrProcessor: TesseractOcrProcessor(),
    // FOSS liveness via Regula's web Face SDK in an embedded WebView; no
    // proprietary native binaries ship in the F-Droid APK (see #665). The
    // capture page is served by the issuer the session points at, so it is read
    // from the provider rather than pinned to one environment. Regula is the
    // only method this build declares: the Iris capture screen could run here
    // too (its client side is free software), but the F-Droid build is kept
    // on Regula for now by choice. Whether the step runs at all is decided per
    // session by the issuer's announcement.
    faceVerificationRunners: (ref) => {
      FaceVerificationMethod.regula: RegulaRunner(
        (_) =>
            RegulaWebFaceService(captureUrl: ref.watch(faceCaptureUrlProvider)),
      ),
    },
    clientFlavor: "fdroid",
  );
}
