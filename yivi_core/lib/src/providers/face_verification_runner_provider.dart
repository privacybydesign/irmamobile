import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:vcmrtd/vcmrtd.dart";

import "regula_face_service_provider.dart";

/// Runs one face verification method's part of the step.
///
/// The issuer assigns a [FaceVerificationMethod] per document session; the
/// shared NFC flow looks up the runner for it and calls [run] after the user
/// confirmed the intro screen. A runner attaches the method's evidence to the
/// issuance request (a liveness transaction id for Regula, a face session id
/// for Iris, a verdict for on-device Iris) and returns it. It throws on cancel
/// or error, exactly like the Regula liveness session did before this seam
/// existed, so the flow lands on the same issuance error screen for every
/// method.
///
/// The two server-verdict methods keep the decision on the issuer side: their
/// runners never judge whether the face matched, they only produce the
/// reference the issuer checks. [FaceVerificationMethod.irisOndevice] is the
/// exception — its engine runs here and its runner reports a verdict the
/// issuer cannot check. It reports a failed verdict rather than throwing, so
/// the attempt is recorded; see
/// `docs/on-device-iris-face-verification-plan.md` §3.
///
/// [portrait] is the chip portrait of the document just read, for the methods
/// that match against it on the device. It is `null` when the document carried
/// none; a runner that needs it must say so rather than proceed.
abstract class FaceVerificationRunner {
  Future<RawDocumentData> run(
    RawDocumentData data, {
    required StartValidationResult start,
    required PassportIssuer issuer,
    required DocumentType documentType,
    ChipPortrait? portrait,
    String? languageCode,
  });
}

/// The runners a flavor can execute, by method. Its keys are the wallet's
/// capability declaration: what this build can run, as a fact, never a
/// preference. The Play Store / App Store build injects all three; the F-Droid
/// build injects Regula only, because the other two methods' engines ship as
/// proprietary binaries.
typedef FaceVerificationRunners =
    Map<FaceVerificationMethod, FaceVerificationRunner>;

/// Empty by default, which declares no capability and makes the flow treat
/// every announcement as one it cannot run. Overridden via
/// `runYiviApp(faceVerificationRunners: ...)`.
final faceVerificationRunnersProvider = Provider<FaceVerificationRunners>(
  (ref) => const {},
);

/// Coarse labels of this build (platform, flavor, version) that the wallet
/// sends with the start-validation request so the issuer can record face
/// verification attempts per build. `null` sends no client block; the issuer
/// then records the attempt without labels, as it does for wallets released
/// before the block existed.
final clientInfoProvider = Provider<ClientInfo?>((ref) => null);

/// Builds a [RegulaFaceService] for the Face API the issuer announced. The
/// native SDK needs that URL (it must run liveness on the same Face API the
/// issuer matches against); the FOSS web implementation ignores it and uses the
/// issuer's own capture page instead.
typedef RegulaFaceServiceFactory =
    RegulaFaceService Function(String faceApiUrl);

/// The Regula method behind the [FaceVerificationRunner] seam: today's
/// liveness session, moved from the NFC flow into a runner. The service is
/// built per run because the announced Face API URL is only known once the
/// session has started.
class RegulaRunner implements FaceVerificationRunner {
  RegulaRunner(this._buildService);

  final RegulaFaceServiceFactory _buildService;

  @override
  Future<RawDocumentData> run(
    RawDocumentData data, {
    required StartValidationResult start,
    required PassportIssuer issuer,
    required DocumentType documentType,
    ChipPortrait? portrait,
    String? languageCode,
  }) async {
    final announcement = start.faceVerification;
    final faceApiUrl = announcement?.faceApiUrl;
    if (announcement?.method != FaceVerificationMethod.regula ||
        faceApiUrl == null) {
      // The flow only picks this runner for a Regula assignment, and the
      // parser drops Regula announcements without a usable URL, so this is a
      // programming error rather than something the user can act on.
      throw StateError(
        "RegulaRunner needs a Regula announcement with a Face API url, "
        "got ${announcement?.method}",
      );
    }
    return withLivenessTransaction(
      _buildService(faceApiUrl),
      data,
      languageCode: languageCode,
    );
  }
}
