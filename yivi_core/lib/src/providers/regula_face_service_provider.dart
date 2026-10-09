import "package:vcmrtd/vcmrtd.dart";

/// Outcome of a Regula liveness session: the liveness verdict and the
/// transaction id that references the proven-live, server-held face.
///
/// Per the face-verification design, the client only performs liveness. The
/// live face never leaves the Face SDK as a raw image; instead the issuer
/// backend matches [transactionId] against the document chip portrait.
class RegulaLivenessResult {
  /// Whether Regula asserted the captured face is live.
  final bool isLive;

  /// The Regula liveness transaction id, sent to the issuer as
  /// `liveness_transaction_id`. Null when the session produced no transaction.
  final String? transactionId;

  const RegulaLivenessResult({
    required this.isLive,
    required this.transactionId,
  });
}

/// Runs a Regula Face SDK liveness session against the Face API backend.
///
/// The Face API (which holds the Regula license server-side) processes the
/// session and stores a proven-live portrait, returning a transaction id. The
/// face match itself is done by the passport issuer against that transaction
/// id, so no raw selfie leaves the SDK.
///
/// Abstracted so the issuance flow can be tested without the native SDK, and so
/// the concrete (non-FOSS) implementation can live in the app flavor rather
/// than in `yivi_core`. Flavors hand it to the flow wrapped in a `RegulaRunner`
/// (see `face_verification_runner_provider.dart`).
abstract class RegulaFaceService {
  /// Initializes the SDK and points it at the Face API backend. Idempotent.
  Future<void> initialize();

  /// Presents Regula's liveness UI and returns the resulting transaction id.
  ///
  /// [languageCode] is the app's active language (e.g. "nl", "de", "en"); the
  /// implementation uses it to localise the Regula screens so they match the
  /// rest of the app.
  Future<RegulaLivenessResult> captureLiveness({String? languageCode});
}

/// Runs a liveness session with [service] (when face verification is enabled)
/// and attaches the resulting transaction id to [data], so the issuer can match
/// the live face against the document chip portrait.
///
/// When [service] is `null`, face verification does not apply to this session
/// (the issuer announced none) and [data] is returned unchanged.
///
/// A non-null [service] means the issuer assigned the Regula method to this
/// session, so the request has to carry a transaction id. A session that yields
/// none is therefore failed here rather than handed to the issuer with the gate
/// silently missing: the caller surfaces it on the issuance error screen, the
/// same place a rejected match ends up. A completed session that does carry an
/// id is forwarded even when liveness did not pass — the id binds the match
/// server-side, so the issuer decides. Errors from the liveness session
/// propagate to the caller.
Future<RawDocumentData> withLivenessTransaction(
  RegulaFaceService? service,
  RawDocumentData data, {
  String? languageCode,
}) async {
  if (service == null) return data;
  final result = await service.captureLiveness(languageCode: languageCode);
  final transactionId = result.transactionId;
  if (transactionId == null) {
    throw StateError(
      "Face verification produced no liveness transaction id (live: ${result.isLive})",
    );
  }
  return data.copyWith(livenessTransactionId: transactionId);
}
