import "dart:io";

import "package:flutter/services.dart";
import "package:flutter_web_auth_2/flutter_web_auth_2.dart";
import "package:url_launcher/url_launcher.dart";

import "session_repository.dart";

/// Opens links: in the browser inside the app, in the one outside it, and
/// the issuer's login of an OpenID4VCI authorization code.
class Browser {
  Browser(this._sessions);

  /// Takes the issuer login's callback.
  final SessionRepository _sessions;

  static const _iiabChannel = MethodChannel("irma.app/iiab");

  /// Opens [url] in the browser inside the app. That only gets https pages;
  /// anything else goes to the user's own browser or the app that handles
  /// the scheme.
  Future<void> openInApp(String url) async {
    if (!Uri.parse(url).isScheme("https")) return openExternally(url);
    if (Platform.isAndroid) {
      await _iiabChannel.invokeMethod("open_browser", url);
    } else {
      final uri = Uri.parse(url);
      final hasOpened = await launchUrl(uri, mode: .inAppWebView);

      // Sometimes launch does not throw an exception itself on failure. Therefore, we also check the return value.
      if (!hasOpened) {
        throw Exception("url could not be opened: $url");
      }
    }
  }

  /// Opens [url] outside the app: on iOS in Safari rather than the Safari
  /// view controller, or in the app a universal link belongs to.
  Future<void> openExternally(String url) async {
    final uri = Uri.parse(url);
    final hasOpened = await launchUrl(uri, mode: .externalApplication);

    // Sometimes launch does not throw an exception itself on failure. Therefore, we also check the return value.
    if (!hasOpened) {
      throw Exception("url could not be opened: $url");
    }
  }

  /// Opens a link (a markdown link, a More tile, the trust sheet) in the
  /// in-app browser.
  Future<void> openLink(String url) => openInApp(url);

  /// Drive an OpenID4VCI authorization-code flow through an
  /// `ASWebAuthenticationSession` (iOS) / Chrome Custom Tab + activity callback
  /// (Android). The OAuth `redirect_uri` is the universal link
  /// `https://open.yivi.app/-/auth-callback` (set in irmago). A bounce page
  /// at that URL JS-redirects to `app.yivi.open://auth-callback?...`, which
  /// the auth session intercepts via `callbackUrlScheme`. The resulting URL
  /// is then handed to its session
  /// ([SessionRepository.answerAuthCallback]).
  Future<void> authenticateOpenID4VCI(String authorizationRequestUrl) async {
    final String result;
    try {
      result = await FlutterWebAuth2.authenticate(
        url: authorizationRequestUrl,
        callbackUrlScheme: "app.yivi.open",
      );
    } on PlatformException catch (e) {
      // User dismissed the browser sheet. The session stays in
      // `requestAuthorizationCode`; the pending screen lets them retry or
      // dismiss. Anything else (e.g. the browser couldn't open) bubbles up.
      if (e.code == "CANCELED") return;
      rethrow;
    }
    _sessions.answerAuthCallback(result);
  }
}

/// Closes the browser inside the app, which a link that opened the app may
/// have come from.
void closeInAppBrowser() => closeInAppWebView();
