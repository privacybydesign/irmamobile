import "../data/irma_repository.dart";
import "session.dart";

const _emailLinkPath = "/-/email";

/// The number of characters in the code the e-mail issuer sends.
const emailCodeLength = 6;

final _codePattern = RegExp("^[A-Za-z0-9]{$emailCodeLength}\$");

/// The universal link in the verification e-mail, for example
/// `https://open.yivi.app/-/email#code=ABC123`. The values sit in the
/// fragment, so they never reach a server log.
///
/// The e-mail issuer leaves the address out (go-email-issuer#105), since the
/// app knows which address it asked a code for. A link that does carry one,
/// as `&email=jan%40example.com`, is still read.
class EmailCodePointer implements Pointer {
  final String? email;
  final String code;

  EmailCodePointer({this.email, required this.code});

  /// Null when [url] is not an e-mail code link.
  static EmailCodePointer? tryParse(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != "https" ||
        !universalLinkHosts.contains(uri.host) ||
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
    if (email != null && !email.contains("@")) return null;
    if (code == null || !_codePattern.hasMatch(code)) return null;
    return EmailCodePointer(email: email, code: code.toUpperCase());
  }

  @override
  Future<void> validate({
    required IrmaRepository irmaRepository,
    RequestorInfo? requestor,
  }) async {}
}
