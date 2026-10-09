import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/routing.dart";
import "package:yivi_core/yivi_core.dart";

import "iris_capture_screen.dart";
import "iris_stream_client.dart";

/// Shows the capture screen for [session] and resolves with what it popped.
typedef IrisCapturePresenter =
    Future<IrisStreamEvent?> Function(FaceSession session);

/// The Iris method behind the [FaceVerificationRunner] seam.
///
/// Verifying the readout with the issuer makes it open a face session at the
/// verifier, bound to the portrait it authenticated; the capture screen then
/// streams frames to that session and the session id goes back with the
/// issuance request. The runner never judges the face: a `completed` stream
/// is forwarded whether or not it passed, so the issuer decides at issuance
/// (as `withLivenessTransaction` forwards a failed Regula liveness). A
/// `failed` stream, a verifier error, a transport failure or a cancel throw,
/// so the flow lands on the generic issuance error screen whose retry starts
/// a new attempt.
class IrisRunner implements FaceVerificationRunner {
  IrisRunner({@visibleForTesting IrisCapturePresenter? present})
    : _present = present ?? _presentCaptureScreen;

  final IrisCapturePresenter _present;

  @override
  Future<RawDocumentData> run(
    RawDocumentData data, {
    required StartValidationResult start,
    required PassportIssuer issuer,
    required DocumentType documentType,
    ChipPortrait? portrait,
    String? languageCode,
  }) async {
    final response = switch (documentType) {
      DocumentType.drivingLicence => await issuer.verifyDrivingLicence(data),
      DocumentType.passport ||
      DocumentType.identityCard => await issuer.verifyPassport(data),
    };
    final session = response.faceSession;
    if (session == null) {
      throw StateError(
        "Iris face verification assigned but the issuer opened no face session",
      );
    }

    return switch (await _present(session)) {
      IrisResultEvent(completed: true) => data.copyWith(
        faceSessionId: session.faceSessionId,
      ),
      IrisResultEvent(:final state) => throw StateError(
        "Iris face verification did not complete: $state",
      ),
      IrisErrorEvent(:final code) => throw StateError(
        "Iris face verification stream error: $code",
      ),
      IrisStateEvent() => throw StateError(
        "Iris capture screen ended on a progress event",
      ),
      null => throw StateError("Iris face verification cancelled"),
    };
  }

  /// Presents the capture screen on the root navigator: the face step runs
  /// from within the NFC reading flow, which has no navigator of its own.
  static Future<IrisStreamEvent?> _presentCaptureScreen(FaceSession session) {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      throw StateError("No navigator available to present the Iris capture");
    }
    return navigator.push<IrisStreamEvent?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => IrisCaptureScreen(session: session),
      ),
    );
  }
}
