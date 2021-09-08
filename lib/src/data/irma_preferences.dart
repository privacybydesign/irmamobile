// This file is not null safe yet.
// @dart=2.11

import 'package:rxdart/subjects.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

class IrmaPreferences {
  static IrmaPreferences _instance;

  static IrmaPreferences get() {
    return _instance ??= IrmaPreferences._internal();
  }

  IrmaPreferences._internal() {
    StreamingSharedPreferences.instance.then((preferences) {
      final longPinPref = preferences.getBool(_longPinKey, defaultValue: true);
      longPinPref.listen(_longPin.add);

      final reportErrorsPref = preferences.getBool(_reportErrorsKey, defaultValue: false);
      reportErrorsPref.listen(_reportErrors.add);

      final startQRScanPref = preferences.getBool(_startQRScanKey, defaultValue: false);
      startQRScanPref.listen(_startQRScan.add);

      final showDisclosureDialogPref = preferences.getBool(_showDisclosureDialogKey, defaultValue: true);
      showDisclosureDialogPref.listen(_showDisclosureDialog.add);

      final developerModePrefVisiblePref = preferences.getBool(_developerModePrefVisibleKey, defaultValue: false);
      developerModePrefVisiblePref.listen(_developerModePrefVisible.add);

      final accepterRootedRiskPref = preferences.getBool(_acceptedRootedRiskKey, defaultValue: false);
      accepterRootedRiskPref.listen(_acceptedRootedRisk.add);
    });
  }

  Future<void> clearAll() {
    return StreamingSharedPreferences.instance.then((preferences) {
      return preferences.clear();
    });
  }

  static const String _longPinKey = "preference.long_pin";
  final BehaviorSubject<bool> _longPin = BehaviorSubject<bool>();

  Stream<bool> getLongPin() {
    return _longPin;
  }

  Future<bool> setLongPin(bool value) {
    return StreamingSharedPreferences.instance.then((preferences) {
      return preferences.setBool(_longPinKey, value);
    });
  }

  static const String _reportErrorsKey = "preference.report_errors";
  final BehaviorSubject<bool> _reportErrors = BehaviorSubject<bool>();

  Stream<bool> getReportErrors() {
    return _reportErrors;
  }

  Future<bool> setReportErrors(bool value) {
    return StreamingSharedPreferences.instance.then((preferences) {
      return preferences.setBool(_reportErrorsKey, value);
    });
  }

  static const String _startQRScanKey = "preference.open_qr_scanner_on_launch";
  final BehaviorSubject<bool> _startQRScan = BehaviorSubject<bool>();

  Stream<bool> getStartQRScan() {
    return _startQRScan;
  }

  Future<bool> setStartQRScan(bool value) {
    return StreamingSharedPreferences.instance.then((preferences) {
      return preferences.setBool(_startQRScanKey, value);
    });
  }

  static const String _showDisclosureDialogKey = "preference.show_disclosure_dialog";
  final BehaviorSubject<bool> _showDisclosureDialog = BehaviorSubject<bool>();

  Stream<bool> getShowDisclosureDialog() {
    return _showDisclosureDialog;
  }

  Future<bool> setShowDisclosureDialog(bool value) {
    return StreamingSharedPreferences.instance.then((preferences) {
      return preferences.setBool(_showDisclosureDialogKey, value);
    });
  }

  static const String _developerModePrefVisibleKey = "preference.devmode_visible";
  final BehaviorSubject<bool> _developerModePrefVisible = BehaviorSubject<bool>();

  Stream<bool> getDeveloperModeVisible() {
    return _developerModePrefVisible;
  }

  Future<bool> setDeveloperModeVisible(bool value) {
    return StreamingSharedPreferences.instance.then((preferences) {
      return preferences.setBool(_developerModePrefVisibleKey, value);
    });
  }

  static const String _acceptedRootedRiskKey = "preference.accepted_rooted_risk";
  final BehaviorSubject<bool> _acceptedRootedRisk = BehaviorSubject<bool>();

  Stream<bool> getAcceptedRootedRisk() {
    return _acceptedRootedRisk;
  }

  Future<bool> setAcceptedRootedRisk(bool value) {
    return StreamingSharedPreferences.instance.then((preferences) {
      return preferences.setBool(_acceptedRootedRiskKey, value);
    });
  }
}
