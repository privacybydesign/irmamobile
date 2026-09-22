import "dart:typed_data";

import "package:iris_sdk_flutter/iris_sdk_flutter.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/yivi_core.dart";

/// Runs the vendor SDK's face verification against [portrait] and resolves
/// with its outcome. The seam the runner is tested through; production hands
/// it [IrisFaceVerifier.verify].
typedef IrisOndeviceVerify =
    Future<IrisVerificationResult> Function(Uint8List portrait);

/// The on-device Iris method behind the [FaceVerificationRunner] seam.
///
/// The vendor SDK owns the whole capture: it presents its own full-screen
/// camera UI, matches the live face against the chip portrait on the device,
/// and hands back a verdict. No frames leave the phone and no service is
/// involved, which is the entire point of this method — and the reason the
/// issuer cannot check what comes back. See
/// `docs/on-device-iris-face-verification-plan.md` §3 for the trust model this
/// accepts.
///
/// Unlike the other two runners, this one carries a decision rather than a
/// reference. A failed verdict is *reported* rather than thrown: the issuance
/// request goes out with `passed: false`, the issuer refuses it with the same
/// error the other methods produce, and the attempt is recorded. Throwing here
/// would land the user on the same error screen while leaving the failure
/// invisible in the recordings, which would flatter this arm in the
/// comparison. A cancel or a missing portrait still throws, as they do
/// everywhere else.
class IrisOndeviceRunner implements FaceVerificationRunner {
  IrisOndeviceRunner({IrisOndeviceVerify? verify})
    : _verify = verify ?? IrisFaceVerifier().verify;

  final IrisOndeviceVerify _verify;

  @override
  Future<RawDocumentData> run(
    RawDocumentData data, {
    required StartValidationResult start,
    required PassportIssuer issuer,
    required DocumentType documentType,
    ChipPortrait? portrait,
    String? languageCode,
  }) async {
    if (portrait == null) {
      // Without the chip portrait there is nothing to match against. The
      // issuer assigns this method to a session, not to a document, so a
      // document whose portrait could not be parsed lands here rather than
      // being filtered out earlier.
      throw StateError(
        "On-device Iris face verification needs the chip portrait, "
        "which this document did not carry",
      );
    }

    final result = await _verify(portrait.bytes);
    // The hash rides along with either verdict: the issuer uses it to refuse a
    // pass that was obtained against another document, and ignores it on a
    // failure, which grants nothing.
    final hash = portrait.sha256Hex;

    return switch (result.outcome) {
      IrisVerificationOutcome.matched => data.copyWith(
        faceOndevicePassed: true,
        faceOndevicePortraitSha256: hash,
      ),
      IrisVerificationOutcome.failed => data.copyWith(
        faceOndevicePassed: false,
        faceOndevicePortraitSha256: hash,
      ),
      IrisVerificationOutcome.cancelled => throw StateError(
        "On-device Iris face verification cancelled",
      ),
    };
  }
}
