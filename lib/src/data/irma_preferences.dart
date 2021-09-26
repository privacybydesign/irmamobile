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
        _longPin = preferences.getBool(_longPinKey, defaultValue: true),
        _reportErrors = preferences.getBool(_reportErrorsKey, defaultValue: false),
        _startQRScan = preferences.getBool(_startQRScanKey, defaultValue: false),
        _showDisclosureDialog = preferences.getBool(_showDisclosureDialogKey, defaultValue: true),
        _developerModePrefVisible = preferences.getBool(_developerModePrefVisibleKey, defaultValue: false),
        _acceptedRootedRisk = preferences.getBool(_acceptedRootedRiskKey, defaultValue: false);

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

  static const String _longPinKey = "preference.long_pin";
  final Preference<bool> _longPin;

  Stream<bool> getLongPin() => _longPin;
  Future<bool> setLongPin(bool value) => _longPin.setValue(value);

  static const String _reportErrorsKey = "preference.report_errors";
  final Preference<bool> _reportErrors;

  Stream<bool> getReportErrors() => _reportErrors;
  Future<bool> setReportErrors(bool value) => _reportErrors.setValue(value);

  static const String _startQRScanKey = "preference.open_qr_scanner_on_launch";
  final Preference<bool> _startQRScan;

  Stream<bool> getStartQRScan() => _startQRScan;
  Future<bool> setStartQRScan(bool value) => _startQRScan.setValue(value);

  static const String _showDisclosureDialogKey = "preference.show_disclosure_dialog";
  final Preference<bool> _showDisclosureDialog;

  Stream<bool> getShowDisclosureDialog() => _showDisclosureDialog;
  Future<bool> setShowDisclosureDialog(bool value) => _showDisclosureDialog.setValue(value);

  static const String _developerModePrefVisibleKey = "preference.devmode_visible";
  final Preference<bool> _developerModePrefVisible;

  Stream<bool> getDeveloperModeVisible() => _developerModePrefVisible;
  Future<bool> setDeveloperModeVisible(bool value) => _developerModePrefVisible.setValue(value);

  static const String _acceptedRootedRiskKey = "preference.accepted_rooted_risk";
  final Preference<bool> _acceptedRootedRisk;

  Stream<bool> getAcceptedRootedRisk() => _acceptedRootedRisk;
  Future<bool> setAcceptedRootedRisk(bool value) => _acceptedRootedRisk.setValue(value);
}
