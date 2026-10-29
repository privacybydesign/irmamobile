import "package:streaming_shared_preferences/streaming_shared_preferences.dart";

/// Light or dark colours, or following the system setting.
enum Appearance {
  system,
  light,
  dark;

  static Appearance parse(String name) =>
      values.firstWhere((a) => a.name == name, orElse: () => system);
}

class IrmaPreferences {
  final String mostRecentTermsUrlNl;
  final String mostRecentTermsUrlEn;

  IrmaPreferences(
    StreamingSharedPreferences preferences, {
    required this.mostRecentTermsUrlNl,
    required this.mostRecentTermsUrlEn,
  }) : _screenshotsEnabled = preferences.getBool(
         _screenshotsEnabledKey,
         defaultValue: false,
       ),
       _acceptedTermsUrl = preferences.getString(
         _acceptedTermsUrlKey,
         defaultValue: "no-terms-accepted",
       ),
       // Please don't arbitrarily change this value, this could hinder the upgrade flow
       // For users before the pin size >5 was introduced.
       _longPin = preferences.getBool(_longPinKey, defaultValue: true),
       _pinVisible = preferences.getBool(_pinVisibleKey, defaultValue: false),
       _reportErrors = preferences.getBool(
         _reportErrorsKey,
         defaultValue: false,
       ),
       _glassOpaque = preferences.getBool(_glassOpaqueKey, defaultValue: false),
       _acceptedRootedRisk = preferences.getBool(
         _acceptedRootedRiskKey,
         defaultValue: false,
       ),
       _biometricEnabled = preferences.getBool(
         _biometricEnabledKey,
         defaultValue: false,
       ),
       _biometricImmediate = preferences.getBool(
         _biometricImmediateKey,
         defaultValue: true,
       ),
       _biometricPromptDismissed = preferences.getBool(
         _biometricPromptDismissedKey,
         defaultValue: false,
       ),
       _preferredLanguageCode = preferences.getString(
         _preferredLanguageKey,
         defaultValue: "",
       ),
       _showNameChangedNotification = preferences.getBool(
         _showNameChangedNotificationKey,
         defaultValue: true,
       ),
       _lastSchemeUpdate = preferences.getInt(
         _lastSchemeUpdateKey,
         defaultValue: 0,
       ),
       _serializedNotifications = preferences.getString(
         _serializedNotificationsKey,
         defaultValue: "",
       ),
       _credentialOrder = preferences.getStringList(
         _credentialOrderKey,
         defaultValue: [],
       ),
       _cardOrder = preferences.getStringList(_cardOrderKey, defaultValue: []),
       _walletView = preferences.getString(_walletViewKey, defaultValue: ""),
       // Until the user picks one, the appearance follows the system, or
       // stays dark for those who turned on the old dark mode preview.
       _appearance = preferences.getString(
         _appearanceKey,
         defaultValue:
             preferences
                 .getBool(_darkModePreviewKey, defaultValue: false)
                 .getValue()
             ? Appearance.dark.name
             : Appearance.system.name,
       ),
       _reviewSuccessCount = preferences.getInt(
         _reviewSuccessCountKey,
         defaultValue: 0,
       ),
       _reviewTimesAsked = preferences.getInt(
         _reviewTimesAskedKey,
         defaultValue: 0,
       ),
       _reviewLastAskEpochMs = preferences.getInt(
         _reviewLastAskEpochMsKey,
         defaultValue: 0,
       ),
       _reviewDone = preferences.getBool(_reviewDoneKey, defaultValue: false),
       _scanTipPending = preferences.getBool(
         _scanTipPendingKey,
         defaultValue: false,
       ),
       _emailLinked = preferences.getBool(_emailLinkedKey, defaultValue: false),
       _emailBannerDismissed = preferences.getBool(
         _emailBannerDismissedKey,
         defaultValue: false,
       ),
       _emailBannerSnoozedUntilMs = preferences.getInt(
         _emailBannerSnoozedUntilMsKey,
         defaultValue: 0,
       ),
       _localBackendHost = preferences.getString(
         _localBackendHostKey,
         defaultValue: "",
       ) {
    // Remove unused IRMA -> Yivi name change notification key
    preferences.remove(_showNameChangeNotificationKey);
    // Remove old value for displaying the dev mode toggle
    preferences.remove(_developerModePrefVisibleKey);
    _retiredDataTabKeys.forEach(preferences.remove);
  }

  static Future<IrmaPreferences> fromInstance({
    required String mostRecentTermsUrlNl,
    required String mostRecentTermsUrlEn,
  }) async => IrmaPreferences(
    await StreamingSharedPreferences.instance,
    mostRecentTermsUrlNl: mostRecentTermsUrlNl,
    mostRecentTermsUrlEn: mostRecentTermsUrlEn,
  );

  // =============================================================================

  static const String _screenshotsEnabledKey = "preference.screenshots_enabled";
  final Preference<bool> _screenshotsEnabled;

  static const String _longPinKey = "preference.long_pin";
  final Preference<bool> _longPin;

  /// Whether entered PIN digits are revealed (the eye toggle on the PIN screen).
  static const String _pinVisibleKey = "preference.pin_visible";
  final Preference<bool> _pinVisible;

  static const String _reportErrorsKey = "preference.report_errors";
  final Preference<bool> _reportErrors;

  /// Developer setting: opaque glass, not see-through (GlassOpaque).
  static const String _glassOpaqueKey = "preference.debug_glass_opaque";
  final Preference<bool> _glassOpaque;

  static const String _acceptedRootedRiskKey =
      "preference.accepted_rooted_risk";
  final Preference<bool> _acceptedRootedRisk;

  /// Whether the user opted in to biometric app-unlock. Default off (opt-in).
  static const String _biometricEnabledKey = "preference.biometric_enabled";
  final Preference<bool> _biometricEnabled;

  /// Whether the biometric scan fires automatically when the lock screen
  /// appears, instead of waiting for a button tap. Default on; only has an
  /// effect while [_biometricEnabled] is true.
  static const String _biometricImmediateKey = "preference.biometric_immediate";
  final Preference<bool> _biometricImmediate;

  /// Whether the one-time biometric opt-in prompt has been answered/dismissed,
  /// so it isn't shown again.
  static const String _biometricPromptDismissedKey =
      "preference.biometric_prompt_dismissed";
  final Preference<bool> _biometricPromptDismissed;

  /// Originates from the notification that  IRMA is ABOUT TO change to Yivi, only used for cleanup-purposes
  static const String _showNameChangeNotificationKey =
      "preference.show_name_change_notification";

  /// Old value that was used for displaying the dev mode toggle,
  /// now it's only used for cleanup-purposes
  static const String _developerModePrefVisibleKey =
      "preference.devmode_visible";

  static const String _preferredLanguageKey =
      "preference.preferred_language_code";
  final Preference<String> _preferredLanguageCode;

  // Value that is used to display the notification that IRMA HAS changed to Yivi
  static const String _showNameChangedNotificationKey =
      "preference.show_name_changed_notification";
  final Preference<bool> _showNameChangedNotification;

  static const String _lastSchemeUpdateKey = "preference.last_schemeupdate";
  final Preference<int> _lastSchemeUpdate;

  // Used to store all notifications
  static const String _serializedNotificationsKey = "preference.notifications";
  final Preference<String> _serializedNotifications;

  static const String _acceptedTermsUrlKey = "preference.accepted_terms_url";
  final Preference<String> _acceptedTermsUrl;

  // Used to store the prefered order of credentials in the data tab
  static const String _credentialOrderKey = "preference.credential_order";
  // list of credential ids stored as json string
  final Preference<List<String>> _credentialOrder;

  // The order of the cards (credential instances, by hash) in the data tab.
  // Replaces the per-type order above, which is read once to seed it.
  static const String _cardOrderKey = "preference.card_order";
  final Preference<List<String>> _cardOrder;

  // How the data tab shows the cards: "stack", "list" or "grid"; empty means
  // the default for the screen size.
  static const String _walletViewKey = "preference.wallet_view";
  final Preference<String> _walletView;

  /// The old "Dark mode (preview)" switch; only read to migrate it.
  static const String _darkModePreviewKey = "preference.dark_mode_preview";
  static const String _appearanceKey = "preference.appearance";
  final Preference<String> _appearance;

  /// Retired: the pins of the old type-based data tab, and its feature flags.
  static const List<String> _retiredDataTabKeys = [
    "preference.favourite_credentials",
    "preference.feature_flag.dataTabV2",
    "preference.feature_flag.dataTabCategories",
    "preference.feature_flag.formFieldsV2",
  ];

  // --- App-store review prompt (see privacybydesign/irmamobile#648) ---------
  // All wiped by clearAll(), so a logout/reset restarts the whole flow.

  /// Successful sessions counted so far (disclosure, issuance and signature).
  static const String _reviewSuccessCountKey =
      "preference.review_success_count";
  final Preference<int> _reviewSuccessCount;

  /// How many times the sentiment gate has been shown: 0, 1 or 2.
  static const String _reviewTimesAskedKey = "preference.review_times_asked";
  final Preference<int> _reviewTimesAsked;

  /// Wall-clock timestamp (ms since epoch) of the last ask, for the re-ask
  /// delay.
  static const String _reviewLastAskEpochMsKey =
      "preference.review_last_ask_epoch_ms";
  final Preference<int> _reviewLastAskEpochMs;

  /// Terminal flag: set once the user answered the gate (yes or not-really) or
  /// the second ask was reached. Never ask again once true.
  static const String _reviewDoneKey = "preference.review_done";
  final Preference<bool> _reviewDone;

  // --- Enrollment -------------------------------------------------------------

  /// Set when the enrollment completes, until the empty Data tab has pointed
  /// out the Scan button once.
  static const String _scanTipPendingKey = "preference.scan_tip_pending";
  final Preference<bool> _scanTipPending;

  // --- E-mail linking ----------------------------------------------------------
  // All wiped by clearAll().

  /// Whether this install has linked an e-mail address to the keyshare server.
  /// The server offers no way to ask, so this is only set by the linking flow.
  static const String _emailLinkedKey = "preference.email_linked";
  final Preference<bool> _emailLinked;

  /// Terminal: the user chose "Negeren", so the banner never shows again.
  static const String _emailBannerDismissedKey =
      "preference.email_banner_dismissed";
  final Preference<bool> _emailBannerDismissed;

  /// Wall-clock time (ms since epoch) before which the banner stays hidden,
  /// set by "Vraag het me later".
  static const String _emailBannerSnoozedUntilMsKey =
      "preference.email_banner_snoozed_until_ms";
  final Preference<int> _emailBannerSnoozedUntilMs;

  /// Host of a local backend setup, set in the debug menu, such as
  /// "localhost" with `adb reverse`. Empty means the real backends.
  static const String _localBackendHostKey = "preference.local_backend_host";
  final Preference<String> _localBackendHost;

  // =============================================================================

  Stream<bool> getScreenshotsEnabled() => _screenshotsEnabled;

  Future<bool> setScreenshotsEnabled(bool value) =>
      _screenshotsEnabled.setValue(value);

  Stream<bool> getLongPin() => _longPin;

  Future<bool> setLongPin(bool value) => _longPin.setValue(value);

  bool getPinVisible() => _pinVisible.getValue();

  Future<bool> setPinVisible(bool value) => _pinVisible.setValue(value);

  Stream<bool> getReportErrors() => _reportErrors;

  Future<bool> setReportErrors(bool value) => _reportErrors.setValue(value);

  Stream<bool> getGlassOpaque() => _glassOpaque;

  Future<bool> setGlassOpaque(bool value) => _glassOpaque.setValue(value);

  Stream<bool> getAcceptedRootedRisk() => _acceptedRootedRisk;

  Future<bool> setAcceptedRootedRisk(bool value) =>
      _acceptedRootedRisk.setValue(value);

  Stream<bool> getBiometricEnabled() => _biometricEnabled;

  Future<bool> setBiometricEnabled(bool value) =>
      _biometricEnabled.setValue(value);

  Stream<bool> getBiometricImmediate() => _biometricImmediate;

  Future<bool> setBiometricImmediate(bool value) =>
      _biometricImmediate.setValue(value);

  Stream<bool> getBiometricPromptDismissed() => _biometricPromptDismissed;

  Future<bool> setBiometricPromptDismissed(bool value) =>
      _biometricPromptDismissed.setValue(value);

  Stream<String> getPreferredLanguageCode() => _preferredLanguageCode;

  /// The current preferred-language override, read synchronously. Empty string
  /// means "follow the system language". Used to compute the effective app
  /// language at bridge startup, before any stream has emitted.
  String get preferredLanguageCode => _preferredLanguageCode.getValue();

  Future<bool> setPreferredLanguageCode(String value) =>
      _preferredLanguageCode.setValue(value);

  Stream<bool> getShowNameChangedNotification() => _showNameChangedNotification;

  Future<bool> setShowNameChangedNotification(bool value) =>
      _showNameChangedNotification.setValue(value);

  Stream<DateTime> getLastSchemeUpdate() => Stream.value(
    DateTime.fromMillisecondsSinceEpoch((_lastSchemeUpdate.getValue() * 1000)),
  );

  Future<bool> setLastSchemeUpdate(DateTime value) =>
      _lastSchemeUpdate.setValue((value.millisecondsSinceEpoch / 1000).round());

  Stream<String> getSerializedNotifications() => _serializedNotifications;

  Future<bool> setSerializedNotifications(String value) =>
      _serializedNotifications.setValue(value);

  Stream<bool> hasAcceptedLatestTerms() =>
      _acceptedTermsUrl.map((url) => url == mostRecentTermsUrlNl);

  Future<bool> markLatestTermsAsAccepted(bool accepted) => _acceptedTermsUrl
      .setValue(accepted ? mostRecentTermsUrlNl : "no-terms-accepted");

  List<String> getCredentialOrder() => _credentialOrder.getValue();

  Future<bool> setCredentialOrder(List<String> order) =>
      _credentialOrder.setValue(order);

  List<String> getCardOrder() => _cardOrder.getValue();

  Future<bool> setCardOrder(List<String> hashes) => _cardOrder.setValue(hashes);

  String getWalletViewNow() => _walletView.getValue();

  Future<bool> setWalletView(String view) => _walletView.setValue(view);

  Stream<Appearance> getAppearance() => _appearance.map(Appearance.parse);

  Future<bool> setAppearance(Appearance appearance) =>
      _appearance.setValue(appearance.name);

  // --- App-store review prompt ----------------------------------------------

  int getReviewSuccessCountNow() => _reviewSuccessCount.getValue();

  int getReviewTimesAskedNow() => _reviewTimesAsked.getValue();

  int getReviewLastAskEpochMsNow() => _reviewLastAskEpochMs.getValue();

  bool getReviewDoneNow() => _reviewDone.getValue();

  Future<bool> incrementReviewSuccessCount() =>
      _reviewSuccessCount.setValue(_reviewSuccessCount.getValue() + 1);

  Future<bool> setReviewDone(bool value) => _reviewDone.setValue(value);

  /// Records that the gate was just shown: bumps the ask count and stamps the
  /// time so the re-ask delay can be evaluated later.
  Future<void> recordReviewAsked({required int nowEpochMs}) async {
    await _reviewTimesAsked.setValue(_reviewTimesAsked.getValue() + 1);
    await _reviewLastAskEpochMs.setValue(nowEpochMs);
  }

  // --- Enrollment -----------------------------------------------------------

  Stream<bool> getScanTipPending() => _scanTipPending;

  Future<bool> markScanTipPending() => _scanTipPending.setValue(true);

  Future<bool> markScanTipShown() => _scanTipPending.setValue(false);

  // --- E-mail linking -------------------------------------------------------

  Stream<bool> getEmailLinked() => _emailLinked;

  Future<bool> markEmailLinked() => _emailLinked.setValue(true);

  Stream<bool> getEmailBannerDismissed() => _emailBannerDismissed;

  Future<bool> dismissEmailBanner() => _emailBannerDismissed.setValue(true);

  Stream<DateTime> getEmailBannerSnoozedUntil() =>
      _emailBannerSnoozedUntilMs.map(DateTime.fromMillisecondsSinceEpoch);

  Future<bool> snoozeEmailBannerUntil(DateTime until) =>
      _emailBannerSnoozedUntilMs.setValue(until.millisecondsSinceEpoch);

  // --- Local backends -------------------------------------------------------

  Stream<String> getLocalBackendHost() => _localBackendHost;

  Future<bool> setLocalBackendHost(String host) =>
      _localBackendHost.setValue(host);

  Future<void> clearAll() {
    // Reset all preferences to their default values
    // except showNameChangedNotification should be false now
    return StreamingSharedPreferences.instance.then((preferences) async {
      await preferences.clear();
      await _showNameChangedNotification.setValue(false);
    });
  }
}
