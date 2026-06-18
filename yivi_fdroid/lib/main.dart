import "package:yivi_core/yivi_core.dart";

import "face_assurance.dart";
import "face_verifier.dart";
import "ocr_processor.dart";

/// ── Face verification on/off switch (F-Droid only) ──────────────────────────
/// `true`  = after reading the NFC chip, verify the user's face against the
///           chip photo, and only add the document once that succeeds.
/// `false` = no face verification; the document is added straight after NFC.
const enableFaceVerification = true;

void main() {
  runYiviApp(
    ocrProcessor: TesseractOcrProcessor(),
    faceVerifier: enableFaceVerification ? FdroidFaceVerifier() : null,
    faceCredentialContent: enableFaceVerification ? faceAssuranceContentBuilder : null,
  );
}
