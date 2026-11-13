import "dart:core";

class ReturnURL {
  final Uri uri;

  /// Schemes a return URL may not have. The return URL is chosen by the requestor
  /// and opened by the app after the session, so it must not be able to run
  /// script, read local files or content providers, or start an arbitrary
  /// Android component. Other schemes stay allowed: returning to the app that
  /// started the session through its own scheme is a supported flow.
  static const _refusedSchemes = {
    "javascript",
    "vbscript",
    "data",
    "blob",
    "about",
    "file",
    "content",
    "intent",
    "android-app",
  };

  /// Parses and validates the given url as return url. In case the url is invalid, it returns null.
  static ReturnURL? parse(String? url) {
    if (url?.isNotEmpty ?? false) {
      try {
        final uri = Uri.parse(url!.trim());
        if (_refusedSchemes.contains(uri.scheme)) {
          return null;
        }
        return ReturnURL._(uri);
      } catch (_) {
        // For now we silently dismiss errors, because the SessionRepository does not expect errors to happen here.
        // Factory constructors may not return null, so therefore we use a static function.
        // The function can be converted to a normal constructor when the error handling is fixed.
      }
    }
    return null;
  }

  const ReturnURL._(this.uri);

  bool get isPhoneNumber => uri.isScheme("tel");
  String get phoneNumber =>
      isPhoneNumber ? toString().substring(4).split(",").first : "";

  /// Whether to open the URL in the in-app browser. Only for https: that browser
  /// has no address bar the user checks, so a cleartext page must not load in it.
  bool get isInApp =>
      uri.isScheme("https") && uri.queryParameters.containsKey("inapp");

  @override
  String toString() => uri.toString();
}
