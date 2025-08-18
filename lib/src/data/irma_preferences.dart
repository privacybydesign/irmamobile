import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

class IrmaPreferences {
  final String mostRecentTermsUrlNl;
  final String mostRecentTermsUrlEn;

  IrmaPreferences(
    StreamingSharedPreferences preferences, {
    required this.mostRecentTermsUrlNl,
    required this.mostRecentTermsUrlEn,
  })  : _screenshotsEnabled = preferences.getBool(_screenshotsEnabledKey, defaultValue: false),
        _acceptedTermsUrl = preferences.getString(_acceptedTermsUrlKey, defaultValue: 'no-terms-accepted'),
        // Please don't arbitrarily change this value, this could hinder the upgrade flow
        // For users before the pin size >5 was introduced.
        _longPin = preferences.getBool(_longPinKey, defaultValue: true),
        _reportErrors = preferences.getBool(_reportErrorsKey, defaultValue: false),
        _showDisclosureDialog = preferences.getBool(_showDisclosureDialogKey, defaultValue: true),
        _acceptedRootedRisk = preferences.getBool(_acceptedRootedRiskKey, defaultValue: false),
        _completedDisclosurePermissionIntro =
            preferences.getBool(_completedDisclosurePermissionIntroKey, defaultValue: false),
        _preferredLanguageCode = preferences.getString(_preferredLanguageKey, defaultValue: ''),
        _showNameChangedNotification = preferences.getBool(_showNameChangedNotificationKey, defaultValue: true),
        _lastSchemeUpdate = preferences.getInt(_lastSchemeUpdateKey, defaultValue: 0),
        _serializedNotifications = preferences.getString(_serializedNotificationsKey, defaultValue: ''),
        _credentialOrder=preferences.getStringList(_credentialOrderKey, defaultValue: []) {
    // Remove unused IRMA -> Yivi name change notification key
    preferences.remove(_showNameChangeNotificationKey);
    // Remove old value for displaying the dev mode toggle
    preferences.remove(_developerModePrefVisibleKey);
  }

  static Future<IrmaPreferences> fromInstance({
    required String mostRecentTermsUrlNl,
    required String mostRecentTermsUrlEn,
  }) async =>
      IrmaPreferences(
        await StreamingSharedPreferences.instance,
        mostRecentTermsUrlNl: mostRecentTermsUrlNl,
        mostRecentTermsUrlEn: mostRecentTermsUrlEn,
      );

  // =============================================================================

  static const String _screenshotsEnabledKey = 'preference.screenshots_enabled';
  final Preference<bool> _screenshotsEnabled;

  static const String _longPinKey = 'preference.long_pin';
  final Preference<bool> _longPin;

  static const String _reportErrorsKey = 'preference.report_errors';
  final Preference<bool> _reportErrors;

  static const String _showDisclosureDialogKey = 'preference.show_disclosure_dialog';
  final Preference<bool> _showDisclosureDialog;

  static const String _acceptedRootedRiskKey = 'preference.accepted_rooted_risk';
  final Preference<bool> _acceptedRootedRisk;

  /// Originates from the notification that  IRMA is ABOUT TO change to Yivi, only used for cleanup-purposes
  static const String _showNameChangeNotificationKey = 'preference.show_name_change_notification';

  /// Old value that was used for displaying the dev mode toggle,
  /// now it's only used for cleanup-purposes
  static const String _developerModePrefVisibleKey = 'preference.devmode_visible';

  static const String _completedDisclosurePermissionIntroKey = 'preference.completed_disclosure_permission_intro';
  final Preference<bool> _completedDisclosurePermissionIntro;

  static const String _preferredLanguageKey = 'preference.preferred_language_code';
  final Preference<String> _preferredLanguageCode;

  // Value that is used to display the notification that IRMA HAS changed to Yivi
  static const String _showNameChangedNotificationKey = 'preference.show_name_changed_notification';
  final Preference<bool> _showNameChangedNotification;

  static const String _lastSchemeUpdateKey = 'preference.last_schemeupdate';
  final Preference<int> _lastSchemeUpdate;

  // Used to store all notifications
  static const String _serializedNotificationsKey = 'preference.notifications';
  final Preference<String> _serializedNotifications;

  static const String _acceptedTermsUrlKey = 'preference.accepted_terms_url';
  final Preference<String> _acceptedTermsUrl;

  // Used to store the prefered order of credentials in the data tab
  static const String _credentialOrderKey = 'preference.credential_order';
  // list of credential ids stored as json string
  final Preference<List<String>> _credentialOrder;

  // =============================================================================

  Stream<bool> getScreenshotsEnabled() => _screenshotsEnabled;

  Future<bool> setScreenshotsEnabled(bool value) => _screenshotsEnabled.setValue(value);

  Stream<bool> getLongPin() => _longPin;

  Future<bool> setLongPin(bool value) => _longPin.setValue(value);

  Stream<bool> getReportErrors() => _reportErrors;

  Future<bool> setReportErrors(bool value) => _reportErrors.setValue(value);

  Stream<bool> getShowDisclosureDialog() => _showDisclosureDialog;

  Future<bool> setShowDisclosureDialog(bool value) => _showDisclosureDialog.setValue(value);

  Stream<bool> getAcceptedRootedRisk() => _acceptedRootedRisk;

  Future<bool> setAcceptedRootedRisk(bool value) => _acceptedRootedRisk.setValue(value);

  Stream<bool> getCompletedDisclosurePermissionIntro() => _completedDisclosurePermissionIntro;

  Future<bool> setCompletedDisclosurePermissionIntro(bool value) => _completedDisclosurePermissionIntro.setValue(value);

  Stream<String> getPreferredLanguageCode() => _preferredLanguageCode;

  Future<bool> setPreferredLanguageCode(String value) => _preferredLanguageCode.setValue(value);

  Stream<bool> getShowNameChangedNotification() => _showNameChangedNotification;

  Future<bool> setShowNameChangedNotification(bool value) => _showNameChangedNotification.setValue(value);

  Stream<DateTime> getLastSchemeUpdate() =>
      Stream.value(DateTime.fromMillisecondsSinceEpoch((_lastSchemeUpdate.getValue() * 1000)));

  Future<bool> setLastSchemeUpdate(DateTime value) =>
      _lastSchemeUpdate.setValue((value.millisecondsSinceEpoch / 1000).round());

  Stream<String> getSerializedNotifications() => _serializedNotifications;

  Future<bool> setSerializedNotifications(String value) => _serializedNotifications.setValue(value);

  Stream<bool> hasAcceptedLatestTerms() => _acceptedTermsUrl.map((url) => url == mostRecentTermsUrlNl);

  Future<bool> markLatestTermsAsAccepted(bool accepted) =>
      _acceptedTermsUrl.setValue(accepted ? mostRecentTermsUrlNl : 'no-terms-accepted');

  List<String> getCredentialOrder() => _credentialOrder.getValue();

  Future<bool> setCredentialOrder(List<String> order) => _credentialOrder.setValue(order);

  Future<void> clearAll() {
    // Reset all preferences to their default values
    // except showNameChangedNotification should be false now
    return StreamingSharedPreferences.instance.then((preferences) async {
      await preferences.clear();
      await _showNameChangedNotification.setValue(false);
    });
  }
}
