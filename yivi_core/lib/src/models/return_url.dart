import 'dart:core';

class ReturnURL {
  final Uri uri;

  /// Parses and validates the given url as return url. In case the url is invalid, it returns null.
  static ReturnURL? parse(String? url) {
    if (url?.isNotEmpty ?? false) {
      try {
        return ReturnURL._(Uri.parse(url!));
      } catch (_) {
        // For now we silently dismiss errors, because the SessionRepository does not expect errors to happen here.
        // Factory constructors may not return null, so therefore we use a static function.
        // The function can be converted to a normal constructor when the error handling is fixed.
      }
    }
    return null;
  }

  const ReturnURL._(this.uri);

  bool get isPhoneNumber => uri.isScheme('tel');
  String get phoneNumber => isPhoneNumber ? toString().substring(4).split(',').first : '';

  bool get isInApp => ['http', 'https'].contains(uri.scheme) && uri.queryParameters.containsKey('inapp');

  @override
  String toString() => uri.toString();
}
