import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:vcmrtd/vcmrtd.dart" show DocumentType;

import "../models/session_state.dart";
import "../providers/contact_issuer_api.dart";
import "../providers/irma_repository_provider.dart";
import "../providers/passport_issuer_provider.dart";
import "../util/nfc_credentials.dart";

/// Sends the user to get a card: Yivi's own flow (e-mail, phone, document)
/// or the issuer's website, remembering in-app launches for the finish.
class IssuanceLauncher {
  IssuanceLauncher(this._ref);

  final Ref _ref;

  // Credential type IDs the user kicked off an in-app launch for (via
  // [open]), pending a session finish. Used at finish time to decide
  // whether to keep the user inside Yivi or hand them off to
  // clientReturnUrl / ArrowBack / send-to-background.
  Set<String> _inAppLaunched = const {};

  void markInAppLaunched(Iterable<String> credentialTypeIds) {
    _inAppLaunched = {..._inAppLaunched, ...credentialTypeIds};
  }

  void clearInAppLaunches() {
    _inAppLaunched = const {};
  }

  /// True when [session] is an issuance session that issued at least one
  /// credential the user launched in-app (via [open]). Used to keep in-app
  /// launches inside Yivi on finish instead of chasing `clientReturnUrl` or
  /// falling through to ArrowBack / send-to-background.
  bool didIssueInAppLaunchedCredential(SessionState session) {
    if (session.type != SessionType.issuance) return false;
    final launched = _inAppLaunched;
    if (launched.isEmpty) return false;
    return session.offeredCredentials?.any(
          (c) => launched.contains(c.credentialId),
        ) ??
        false;
  }

  /// Points Yivi's own flow for [credentialId] at the issuer of [issueURL],
  /// as opening it does, but without opening its screens: the sheet shows
  /// the steps itself. False without an issue URL or an own flow.
  bool prepareEmbeddedFlow(String credentialId, String? issueURL) {
    final flow = embeddedFlowOf(credentialId);
    final url = issueURL ?? "";
    if (flow == null || url.isEmpty) return false;
    final base = _issuerBase(url);
    switch (flow) {
      case EmbeddedFlow.email:
        _ref.read(emailIssuerUrlProvider.notifier).set(base);
      case EmbeddedFlow.phone:
        _ref.read(smsIssuerUrlProvider.notifier).set(base);
      case EmbeddedFlow.document:
        _ref.read(passportIssuerUrlProvider.notifier).set(base);
    }
    return true;
  }

  /// Whether obtaining [credentialId] (given an issue URL) sends the user to
  /// the issuer's website: no embedded in-app flow handles it and it does not
  /// open a native app through a universal link.
  bool issuesViaWebsite(String credentialId) {
    if (_hasEmbeddedFlow(credentialId)) return false;
    return !_issuesViaUniversalLink(credentialId);
  }

  bool _issuesViaUniversalLink(String credentialId) =>
      _ref.read(irmaRepositoryProvider).issuesViaUniversalLink(credentialId);

  /// Unified entry point for "user tapped Get / Reobtain inside the app
  /// and we need to take them to the issuer to obtain a credential".
  ///
  /// Behaviour:
  /// - For known embedded scheme credentials (pbdf/pbdf-staging passport,
  ///   drivinglicence, idcard, mobilenumber, email), point Yivi's own flow
  ///   at the issuer and stop: those are added in the sheet, which never
  ///   comes here (asserted in debug builds).
  /// - Otherwise, mark the credential as launched in-app (so the
  ///   resulting issuance session's finish lands on the success screen
  ///   instead of `clientReturnUrl` / ArrowBack / send-to-background) and
  ///   open the URL. Universal-link credential types open outside the app
  ///   so the OS can dispatch the link to a registered native app (UZI
  ///   register, Belastingdienst), as do the types whose website breaks in
  ///   the in-app browser on this platform ([_externalBrowserTypes]);
  ///   everything else opens in the in-app browser.
  ///
  /// Throws an [UnsupportedError] without an issue URL.
  Future<void> open(String credentialId, String? issueURL) async {
    // issueURL is already resolved to the effective app language by irmago.
    final url = issueURL;
    if (url == null || url.isEmpty) {
      throw UnsupportedError(
        "Credential type $credentialId does not have a suitable issue url",
      );
    }

    if (_hasEmbeddedFlow(credentialId)) {
      if (!prepareEmbeddedFlow(credentialId, url)) return;
      // E-mail addresses, phone numbers and documents are added in the
      // sheet (IssueSheet), which never comes here.
      assert(false, "${embeddedFlowOf(credentialId)} is added in the sheet");
      return;
    }

    markInAppLaunched([credentialId]);

    final browser = _ref.read(browserProvider);
    if (_issuesViaUniversalLink(credentialId) ||
        _issuesInExternalBrowser(credentialId)) {
      return browser.openExternally(url);
    }

    return browser.openInApp(url);
  }

  /// Credential types whose issuer website breaks in the in-app browser, per
  /// platform: their issue URL opens in the browser outside the app.
  // TODO Remove when disclosure sessions can be started from custom tabs
  static const _externalBrowserTypes = <TargetPlatform, Set<String>>{
    TargetPlatform.iOS: {
      "pbdf.gemeente.address",
      "pbdf.gemeente.personalData",
      "pbdf.PubHubs.account",
      "irma-demo.PubHubs.account",
    },
    TargetPlatform.android: {
      "pbdf.pbdf.idin",
      // Shares iDIN's issuer website.
      "pbdf.pbdf.ageLimits",
      "pbdf.PubHubs.account",
      "irma-demo.PubHubs.account",
    },
  };

  /// Whether the issue URL of [credentialId] opens in the browser outside
  /// the app on this platform.
  static bool _issuesInExternalBrowser(String credentialId) =>
      _externalBrowserTypes[defaultTargetPlatform]?.contains(credentialId) ??
      false;

  /// The base of [url] (scheme, host and port): the issuer that Yivi's own
  /// flows talk to.
  static String _issuerBase(String url) {
    final uri = Uri.parse(url);
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }
}

/// Sends the user to get a card. Holds which cards were launched in the
/// app until their issuance finishes.
final issuanceLauncherProvider = Provider<IssuanceLauncher>(
  IssuanceLauncher.new,
);

/// Yivi's own flows for the credentials it issues itself.
enum EmbeddedFlow { email, phone, document }

/// The documents ([nfcRequiringCredentialIds]), the phone number and the
/// e-mail address, in production and staging.
const _embeddedFlowIds = {
  ...nfcRequiringCredentialIds,
  "pbdf.sidn-pbdf.mobilenumber",
  "pbdf.sidn-pbdf.email",
  "pbdf-staging.sidn-pbdf.mobilenumber",
  "pbdf-staging.sidn-pbdf.email",
};

/// Whether Yivi issues [credentialId] itself, in its own screens (e-mail,
/// phone number, documents), instead of on the issuer's website.
bool _hasEmbeddedFlow(String credentialId) =>
    _embeddedFlowIds.contains(credentialId);

/// Which of Yivi's own flows issues [credentialId], if any.
EmbeddedFlow? embeddedFlowOf(String credentialId) {
  final type = credentialId.split(".").skip(1).join(".");
  return switch (type) {
    _ when !_hasEmbeddedFlow(credentialId) => null,
    "sidn-pbdf.email" => EmbeddedFlow.email,
    "sidn-pbdf.mobilenumber" => EmbeddedFlow.phone,
    _ => EmbeddedFlow.document,
  };
}

/// Which document issues [credentialId] (`pbdf.pbdf.passport` and its
/// staging twin, and so on), if any.
DocumentType? documentTypeOf(String credentialId) =>
    switch (credentialId.split(".").last) {
      "passport" => .passport,
      "idcard" => .identityCard,
      "residencepermit" => .residencePermit,
      "drivinglicence" => .drivingLicence,
      _ => null,
    };
