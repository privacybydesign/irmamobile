import "../models/irma_configuration.dart";
import "../models/translated_value.dart";

/// Outcome of deciding how to handle a credential (re)issue request.
///
/// See [resolveReissue].
sealed class ReissueResolution {
  const ReissueResolution();
}

/// The credential can be (re)obtained; the issuer flow should be opened with
/// [url].
class ReissueAvailable extends ReissueResolution {
  final String url;
  const ReissueAvailable(this.url);
}

/// The credential's issuer endpoint no longer exists in the current scheme
/// configuration, so reissuing is not possible and the user should be told the
/// credential is no longer available (instead of being sent to a bare 404).
class ReissueUnavailable extends ReissueResolution {
  const ReissueUnavailable();
}

/// Decide how to handle a reissue/reobtain request for [credentialId].
///
/// A credential the user holds carries the issue URL that was current when it
/// was obtained ([fallbackIssueUrl]). When the scheme later removes or replaces
/// that credential type, following the stored URL lands the user on a bare 404.
///
/// To avoid that this prefers the issue URL from the freshly-loaded
/// [irmaConfiguration]:
/// - If the credential type is still present with a non-empty issue URL, that
///   URL is used. A scheme update that replaces a credential with a newer
///   version updates this URL, so following it transparently redirects the user
///   to the replacement.
/// - If the credential type is present in the configuration but no longer has an
///   issue URL, or is no longer present at all, the credential is considered no
///   longer available ([ReissueUnavailable]).
/// - If the configuration has not been loaded yet ([irmaConfiguration] is
///   `null`), fall back to the URL stored on the held credential so reobtaining
///   keeps working before the scheme is available; only when that is empty too
///   is the credential considered unavailable.
ReissueResolution resolveReissue({
  required String credentialId,
  required TranslatedValue? fallbackIssueUrl,
  required IrmaConfiguration? irmaConfiguration,
  required String languageCode,
}) {
  if (irmaConfiguration != null) {
    final configCredential = irmaConfiguration.credentialTypes[credentialId];
    // Credential type removed from the scheme → endpoint no longer exists.
    if (configCredential == null) {
      return const ReissueUnavailable();
    }
    final configUrl = configCredential.issueUrl.translate(
      languageCode,
      fallback: "",
    );
    // Still present, and possibly pointing at a newer replacement endpoint.
    return configUrl.isEmpty
        ? const ReissueUnavailable()
        : ReissueAvailable(configUrl);
  }

  // Configuration not loaded yet: fall back to the stored issue URL.
  final fallbackUrl = fallbackIssueUrl?.translate(languageCode, fallback: "");
  return (fallbackUrl == null || fallbackUrl.isEmpty)
      ? const ReissueUnavailable()
      : ReissueAvailable(fallbackUrl);
}
