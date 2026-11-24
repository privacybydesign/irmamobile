import "package:streaming_shared_preferences/streaming_shared_preferences.dart";

import "pref.dart";

/// Light or dark colours, or following the system setting.
enum Appearance {
  system,
  light,
  dark;

  static Appearance parse(String name) =>
      values.firstWhere((a) => a.name == name, orElse: () => system);
}

/// The app's stored preferences. The keys, defaults and stored types must
/// never change: an update would lose what users stored.
class IrmaPreferences {
  final String mostRecentTermsUrlNl;
  final String mostRecentTermsUrlEn;

  IrmaPreferences(
    StreamingSharedPreferences p, {
    required this.mostRecentTermsUrlNl,
    required this.mostRecentTermsUrlEn,
  }) : screenshotsEnabled = Pref.of(
         p.getBool("preference.screenshots_enabled", defaultValue: false),
       ),
       // Please don't arbitrarily change this value, this could hinder the
       // upgrade flow for users before the pin size >5 was introduced.
       longPin = Pref.of(p.getBool("preference.long_pin", defaultValue: true)),
       pinVisible = Pref.of(
         p.getBool("preference.pin_visible", defaultValue: false),
       ),
       reportErrors = Pref.of(
         p.getBool("preference.report_errors", defaultValue: false),
       ),
       acceptedRootedRisk = Pref.of(
         p.getBool("preference.accepted_rooted_risk", defaultValue: false),
       ),
       acceptedEnvironmentRisk = Pref.of(
         p.getBool("preference.accepted_environment_risk", defaultValue: false),
       ),
       biometricEnabled = Pref.of(
         p.getBool("preference.biometric_enabled", defaultValue: false),
       ),
       biometricImmediate = Pref.of(
         p.getBool("preference.biometric_immediate", defaultValue: true),
       ),
       biometricPromptDismissed = Pref.of(
         p.getBool(
           "preference.biometric_prompt_dismissed",
           defaultValue: false,
         ),
       ),
       preferredLanguageCode = Pref.of(
         p.getString("preference.preferred_language_code", defaultValue: ""),
       ),
       showNameChangedNotification = Pref.of(
         p.getBool(
           "preference.show_name_changed_notification",
           defaultValue: true,
         ),
       ),
       lastSchemeUpdate = Pref.mapped<int, DateTime>(
         p.getInt("preference.last_schemeupdate", defaultValue: 0),
         decode: (seconds) =>
             DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
         encode: (date) => (date.millisecondsSinceEpoch / 1000).round(),
       ),
       serializedNotifications = Pref.of(
         p.getString("preference.notifications", defaultValue: ""),
       ),
       _acceptedTermsUrl = Pref.of(
         p.getString(
           "preference.accepted_terms_url",
           defaultValue: _noTermsAccepted,
         ),
       ),
       _acceptedTermsAt = Pref.of(
         p.getInt("preference.accepted_terms_at_epoch_ms", defaultValue: 0),
       ),
       acceptedLatestTerms = Pref.mapped<String, bool>(
         p.getString(
           "preference.accepted_terms_url",
           defaultValue: _noTermsAccepted,
         ),
         decode: (url) => url == mostRecentTermsUrlNl,
         encode: (accepted) =>
             accepted ? mostRecentTermsUrlNl : _noTermsAccepted,
       ),
       credentialOrder = Pref.of(
         p.getStringList("preference.credential_order", defaultValue: []),
       ),
       cardOrder = Pref.of(
         p.getStringList("preference.card_order", defaultValue: []),
       ),
       walletView = Pref.of(
         p.getString("preference.wallet_view", defaultValue: ""),
       ),
       cardMotion = Pref.of(
         p.getString("preference.card_motion", defaultValue: ""),
       ),
       // Until the user picks one, the appearance follows the system, or
       // stays dark for those who turned on the old dark mode preview.
       appearance = Pref.mapped<String, Appearance>(
         p.getString(
           "preference.appearance",
           defaultValue:
               p
                   .getBool("preference.dark_mode_preview", defaultValue: false)
                   .getValue()
               ? Appearance.dark.name
               : Appearance.system.name,
         ),
         decode: Appearance.parse,
         encode: (appearance) => appearance.name,
       ),
       reviewSuccessCount = Pref.of(
         p.getInt("preference.review_success_count", defaultValue: 0),
       ),
       reviewTimesAsked = Pref.of(
         p.getInt("preference.review_times_asked", defaultValue: 0),
       ),
       reviewLastAskEpochMs = Pref.of(
         p.getInt("preference.review_last_ask_epoch_ms", defaultValue: 0),
       ),
       reviewDone = Pref.of(
         p.getBool("preference.review_done", defaultValue: false),
       ),
       scanTipPending = Pref.of(
         p.getBool("preference.scan_tip_pending", defaultValue: false),
       ),
       emailLinked = Pref.of(
         p.getBool("preference.email_linked", defaultValue: false),
       ),
       emailBannerDismissed = Pref.of(
         p.getBool("preference.email_banner_dismissed", defaultValue: false),
       ),
       emailBannerSnoozedUntil = Pref.mapped<int, DateTime>(
         p.getInt("preference.email_banner_snoozed_until_ms", defaultValue: 0),
         decode: DateTime.fromMillisecondsSinceEpoch,
         encode: (date) => date.millisecondsSinceEpoch,
       ),
       localBackendHost = Pref.of(
         p.getString("preference.local_backend_host", defaultValue: ""),
       ) {
    _retiredKeys.forEach(p.remove);
  }

  static Future<IrmaPreferences> fromInstance({
    required String mostRecentTermsUrlNl,
    required String mostRecentTermsUrlEn,
  }) async => IrmaPreferences(
    await StreamingSharedPreferences.instance,
    mostRecentTermsUrlNl: mostRecentTermsUrlNl,
    mostRecentTermsUrlEn: mostRecentTermsUrlEn,
  );

  static const _noTermsAccepted = "no-terms-accepted";

  /// Retired: the notification that IRMA was about to become Yivi, the old
  /// developer mode toggle visibility, the pins of the old type-based data
  /// tab, its feature flags, and the old disclosure screen's dialog and intro.
  /// (`preference.dark_mode_preview` is read once above, to migrate it.)
  static const List<String> _retiredKeys = [
    "preference.show_name_change_notification",
    "preference.devmode_visible",
    "preference.favourite_credentials",
    "preference.feature_flag.dataTabV2",
    "preference.feature_flag.dataTabCategories",
    "preference.feature_flag.formFieldsV2",
    "preference.show_disclosure_dialog",
    "preference.completed_disclosure_permission_intro",
  ];

  final Pref<bool> screenshotsEnabled;

  /// Whether the PIN has more than five digits.
  final Pref<bool> longPin;

  /// Whether entered PIN digits are revealed (the eye toggle on the PIN
  /// screen).
  final Pref<bool> pinVisible;

  final Pref<bool> reportErrors;
  final Pref<bool> acceptedRootedRisk;

  /// Kept apart from [acceptedRootedRisk]: accepting the risk of a rooted or
  /// jailbroken device says nothing about an emulator, a cloned app or a
  /// hooking framework.
  final Pref<bool> acceptedEnvironmentRisk;

  /// Whether the user opted in to biometric app-unlock. Default off (opt-in).
  final Pref<bool> biometricEnabled;

  /// Whether the biometric scan fires automatically when the lock screen
  /// appears, instead of waiting for a button tap. Default on; only has an
  /// effect while [biometricEnabled] is true.
  final Pref<bool> biometricImmediate;

  /// Whether the one-time biometric opt-in prompt has been answered or
  /// dismissed, so it isn't shown again.
  final Pref<bool> biometricPromptDismissed;

  /// The language the user picked; empty follows the system language.
  final Pref<String> preferredLanguageCode;

  /// Whether to show the notice that IRMA has changed to Yivi.
  final Pref<bool> showNameChangedNotification;

  /// When the schemes were last updated; stored in seconds.
  final Pref<DateTime> lastSchemeUpdate;

  /// The notification records, as JSON.
  final Pref<String> serializedNotifications;

  /// Whether the latest terms were accepted: stored as the URL of the terms
  /// accepted, which counts when it is the latest Dutch one.
  final Pref<bool> acceptedLatestTerms;

  /// The stored terms URL, as [acceptedLatestTerms] reads it.
  final Pref<String> _acceptedTermsUrl;

  /// When the user accepted the terms in [_acceptedTermsUrl] (ms since
  /// epoch), or 0 when unknown: no terms accepted, or accepted before this
  /// was recorded. Together with the versioned URL this is the record of the
  /// consent.
  final Pref<int> _acceptedTermsAt;

  /// Accepts (or withdraws) the latest terms, and records when.
  Future<void> acceptLatestTerms(bool accepted) async {
    await _acceptedTermsAt.set(
      accepted ? DateTime.now().millisecondsSinceEpoch : 0,
    );
    await acceptedLatestTerms.set(accepted);
  }

  /// The versioned terms URL the user accepted, or null when none was.
  String? get acceptedTermsUrl {
    final url = _acceptedTermsUrl.value;
    return url == _noTermsAccepted ? null : url;
  }

  /// When the user accepted [acceptedTermsUrl], or null when that is unknown.
  DateTime? get acceptedTermsAt {
    final epochMs = _acceptedTermsAt.value;
    return epochMs == 0 ? null : DateTime.fromMillisecondsSinceEpoch(epochMs);
  }

  /// The preferred order of credential types in the data tab; only read to
  /// seed [cardOrder].
  final Pref<List<String>> credentialOrder;

  /// The order of the cards (credential instances, by hash) in the data tab.
  final Pref<List<String>> cardOrder;

  /// How the data tab shows the cards: "stack", "list" or "grid"; empty
  /// means the default for the screen size.
  final Pref<String> walletView;

  /// How a card opening from the stack moves (debug settings), encoded;
  /// empty for the defaults.
  final Pref<String> cardMotion;

  /// Light, dark or the system's; stored by name.
  final Pref<Appearance> appearance;

  // --- App-store review prompt (see privacybydesign/irmamobile#648) -------
  // All wiped by clearAll(), so a logout/reset restarts the whole flow.

  /// Successful sessions counted so far (disclosure, issuance and
  /// signature).
  final Pref<int> reviewSuccessCount;

  /// How many times the sentiment gate has been shown: 0, 1 or 2.
  final Pref<int> reviewTimesAsked;

  /// Wall-clock timestamp (ms since epoch) of the last ask, for the re-ask
  /// delay.
  final Pref<int> reviewLastAskEpochMs;

  /// Terminal flag: set once the user answered the gate (yes or not-really)
  /// or the second ask was reached. Never ask again once true.
  final Pref<bool> reviewDone;

  /// Set when the enrollment completes, until the empty Data tab has pointed
  /// out the Scan button once.
  final Pref<bool> scanTipPending;

  // --- E-mail linking (all wiped by clearAll()) ----------------------------

  /// Whether this install has linked an e-mail address to the keyshare
  /// server. The server offers no way to ask, so this is only set by the
  /// linking flow.
  final Pref<bool> emailLinked;

  /// Terminal: the user chose "Negeren", so the banner never shows again.
  final Pref<bool> emailBannerDismissed;

  /// Before when the banner stays hidden, set by "Ask me later"; stored in
  /// milliseconds.
  final Pref<DateTime> emailBannerSnoozedUntil;

  /// Host of a local backend setup, set in the debug menu, such as
  /// "localhost" with `adb reverse`. Empty means the real backends.
  final Pref<String> localBackendHost;

  /// Counts one more successful session for the review prompt.
  Future<bool> incrementReviewSuccessCount() =>
      reviewSuccessCount.set(reviewSuccessCount.value + 1);

  /// Records that the review gate was just shown: bumps the ask count and
  /// stamps the time so the re-ask delay can be evaluated later.
  Future<void> recordReviewAsked({required int nowEpochMs}) async {
    await reviewTimesAsked.set(reviewTimesAsked.value + 1);
    await reviewLastAskEpochMs.set(nowEpochMs);
  }

  /// Resets every preference to its default, except that the name-changed
  /// notice stays off.
  Future<void> clearAll() =>
      StreamingSharedPreferences.instance.then((preferences) async {
        await preferences.clear();
        await showNameChangedNotification.set(false);
      });
}
