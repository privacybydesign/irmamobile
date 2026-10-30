import "package:equatable/equatable.dart";

/// The scan state the scan service adds to the return URL.
enum DocumentScanState { pending, completed, failed, unknown }

enum DocumentScanFailure {
  /// The app has no camera permission, so the page cannot take photos.
  cameraDenied,

  /// The scan page did not load, or answered with an error (e.g. an expired
  /// link), or redirected to the return URL without a transaction ID.
  pageFailed,
}

/// How a document scan in the [DocumentScanWebView] ended.
sealed class DocumentScanOutcome extends Equatable {
  const DocumentScanOutcome();

  @override
  List<Object?> get props => [];

  @override
  bool get stringify => true;
}

/// The scan page redirected to the return URL. This only says the user is done
/// on the scan page: the business wallet fetches the result by [transactionId]
/// and decides whether the document is genuine.
final class DocumentScanFinished extends DocumentScanOutcome {
  const DocumentScanFinished({
    required this.transactionId,
    required this.state,
    this.resultId,
  });

  final String transactionId;
  final DocumentScanState state;

  /// Only present when [state] is [DocumentScanState.completed].
  final String? resultId;

  @override
  List<Object?> get props => [transactionId, state, resultId];
}

/// The user went back before finishing the scan.
final class DocumentScanCancelled extends DocumentScanOutcome {
  const DocumentScanCancelled();
}

final class DocumentScanFailed extends DocumentScanOutcome {
  const DocumentScanFailed(this.reason);

  final DocumentScanFailure reason;

  @override
  List<Object?> get props => [reason];
}

/// Whether [url] is the return URL the scan page redirects to when the scan is
/// done. Only the query may differ, as the scan service adds its parameters
/// there; matching the path exactly keeps e.g. `/return-other` from counting as
/// `/return`.
bool isDocumentScanReturnUrl(Uri url, Uri returnUrl) =>
    url.scheme == returnUrl.scheme &&
    url.host == returnUrl.host &&
    url.port == returnUrl.port &&
    url.path == returnUrl.path;

/// Reads the outcome from the return URL, to which the scan service adds
/// `trxid`, `state` and `resultid`.
DocumentScanOutcome documentScanOutcomeFromReturnUrl(Uri url) {
  final transactionId = url.queryParameters["trxid"];
  if (transactionId == null || transactionId.isEmpty) {
    return const DocumentScanFailed(DocumentScanFailure.pageFailed);
  }
  final resultId = url.queryParameters["resultid"];
  return DocumentScanFinished(
    transactionId: transactionId,
    state:
        DocumentScanState.values.asNameMap()[url.queryParameters["state"]] ??
        DocumentScanState.unknown,
    resultId: resultId == null || resultId.isEmpty ? null : resultId,
  );
}

/// Whether the web view may show [url]: only pages over HTTPS on the host of
/// the scan link, so the camera is never handed to another site.
bool isDocumentScanPage(Uri url, Uri scanUrl) =>
    url.scheme == "https" && url.host == scanUrl.host;
