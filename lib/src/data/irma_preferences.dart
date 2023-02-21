import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

class IrmaPreferences {
  static IrmaPreferences? _instance;

  // This function is deprecated, because it ignores the StreamingSharedPreferences instance to return a future.
  @Deprecated('Use preferences from IrmaRepository instead')
  static IrmaPreferences get() {
    if (_instance == null) throw Exception('IrmaPreferences has not been initialized');
    return _instance!;
  }

  // This factory constructor can be removed when IrmaPreferences.get() is phased out.
  // The standard constructor below can be converted to default constructor then.
  factory IrmaPreferences(StreamingSharedPreferences preferences) {
    _instance = IrmaPreferences._(preferences);
    return _instance!;
  }

  IrmaPreferences._(StreamingSharedPreferences preferences)
      : _screenshotsEnabled = preferences.getBool(_screenshotsEnabledKey, defaultValue: false),
        // Please don't arbitrarily change this value, this could hinder the upgrade flow
        // For users before the pin size >5 was introduced.
        _longPin = preferences.getBool(_longPinKey, defaultValue: true),
        _reportErrors = preferences.getBool(_reportErrorsKey, defaultValue: false),
        _startQRScan = preferences.getBool(_startQRScanKey, defaultValue: false),
        _showDisclosureDialog = preferences.getBool(_showDisclosureDialogKey, defaultValue: true),
        _acceptedRootedRisk = preferences.getBool(_acceptedRootedRiskKey, defaultValue: false),
        _completedDisclosurePermissionIntro =
            preferences.getBool(_completedDisclosurePermissionIntroKey, defaultValue: false) {
    // Remove unused IRMA -> Yivi name change notification key
    preferences.remove(_showNameChangeNotificationKey);
    // Remove old value for displaying the dev mode toggle
    preferences.remove(_developerModePrefVisibleKey);
  }

  static Future<IrmaPreferences> fromInstance() async => IrmaPreferences(await StreamingSharedPreferences.instance);

  Future<void> clearAll() {
    return StreamingSharedPreferences.instance.then((preferences) async {
      await preferences.clear();
    });
  }

  static const String _screenshotsEnabledKey = 'preference.screenshots_enabled';
  final Preference<bool> _screenshotsEnabled;

  Stream<bool> getScreenshotsEnabled() => _screenshotsEnabled;
  Future<bool> setScreenshotsEnabled(bool value) => _screenshotsEnabled.setValue(value);

  static const String _longPinKey = 'preference.long_pin';
  final Preference<bool> _longPin;

  Stream<bool> getLongPin() => _longPin;
  Future<bool> setLongPin(bool value) => _longPin.setValue(value);

  static const String _reportErrorsKey = 'preference.report_errors';
  final Preference<bool> _reportErrors;

  Stream<bool> getReportErrors() => _reportErrors;
  Future<bool> setReportErrors(bool value) => _reportErrors.setValue(value);

  static const String _startQRScanKey = 'preference.open_qr_scanner_on_launch';
  final Preference<bool> _startQRScan;

  Stream<bool> getStartQRScan() => _startQRScan;
  Future<bool> setStartQRScan(bool value) => _startQRScan.setValue(value);

  static const String _showDisclosureDialogKey = 'preference.show_disclosure_dialog';
  final Preference<bool> _showDisclosureDialog;

  Stream<bool> getShowDisclosureDialog() => _showDisclosureDialog;
  Future<bool> setShowDisclosureDialog(bool value) => _showDisclosureDialog.setValue(value);

  static const String _acceptedRootedRiskKey = 'preference.accepted_rooted_risk';
  final Preference<bool> _acceptedRootedRisk;

  Stream<bool> getAcceptedRootedRisk() => _acceptedRootedRisk;
  Future<bool> setAcceptedRootedRisk(bool value) => _acceptedRootedRisk.setValue(value);

  /// Originates from the IRMA -> Yivi name change, only used for cleanup-purposes
  static const String _showNameChangeNotificationKey = 'preference.show_name_change_notification';

  /// Old value that was used for displaying the dev mode toggle,
  /// now it's only used for cleanup-purposes
  static const String _developerModePrefVisibleKey = 'preference.devmode_visible';

  static const String _completedDisclosurePermissionIntroKey = 'preference.completed_disclosure_permission_intro';
  final Preference<bool> _completedDisclosurePermissionIntro;

  Stream<bool> getCompletedDisclosurePermissionIntro() => _completedDisclosurePermissionIntro;
  Future<bool> setCompletedDisclosurePermissionIntro(bool value) => _completedDisclosurePermissionIntro.setValue(value);
}
