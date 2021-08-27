import 'dart:core';

class ReturnURL {
  final Uri uri;

  /// Parses and validates the given url as return url. In case the url is invalid, it returns null.
  factory ReturnURL(String url) {
    if (url?.isNotEmpty ?? false) {
      try {
        return ReturnURL._(Uri.parse(url));
      } catch (_) {
        // Nop
      }
    }
    return null;
  }

  const ReturnURL._(this.uri);

  bool get isReturnPhoneNumber => uri.isScheme('tel');
  String get phoneNumber => isReturnPhoneNumber ? toString().substring(4).split(',').first : '';

  bool get isInApp => ['http', 'https'].contains(uri.scheme) && uri.queryParameters.containsKey("inapp");

  @override
  String toString() => uri.toString();
}
