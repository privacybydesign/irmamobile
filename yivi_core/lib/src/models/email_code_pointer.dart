import "../data/irma_repository.dart";
import "session.dart";

const _universalLinkHosts = {"open.yivi.app", "open.staging.yivi.app"};
const _emailLinkPath = "/-/email";
final _codePattern = RegExp(r"^[A-Za-z0-9]{6}$");

/// The universal link in the verification e-mail, for example
/// `https://open.yivi.app/-/email#code=ABC123&email=jan%40example.com`. Both
/// values sit in the fragment, so they never reach a server log.
class EmailCodePointer implements Pointer {
  final String email;
  final String code;

  EmailCodePointer({required this.email, required this.code});

  /// Null when [url] is not an e-mail code link.
  static EmailCodePointer? tryParse(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != "https" ||
        !_universalLinkHosts.contains(uri.host) ||
        uri.path != _emailLinkPath) {
      return null;
    }

    final Map<String, String> fragment;
    try {
      fragment = Uri.splitQueryString(uri.fragment);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }

    final email = fragment["email"]?.trim();
    final code = fragment["code"];
    if (email == null || !email.contains("@")) return null;
    if (code == null || !_codePattern.hasMatch(code)) return null;
    return EmailCodePointer(email: email, code: code.toUpperCase());
  }

  @override
  Future<void> validate({
    required IrmaRepository irmaRepository,
    RequestorInfo? requestor,
  }) async {}
}
