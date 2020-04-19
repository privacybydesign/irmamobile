import 'package:quiver/async.dart';
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

      final pinBlockedUntilPref = preferences.getString(_pinBlockedUntilKey, defaultValue: "");
      pinBlockedUntilPref.listen(listenLockedPref);
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

  static const String _pinBlockedUntilKey = "preference.pin_blocked_until";
  CountdownTimer _pinBlockedCountdown;
  final BehaviorSubject<Duration> _pinBlockedFor = BehaviorSubject<Duration>();

  // Create derived steam that counts the seconds until pin can be used again.
  void listenLockedPref(String prefValue) {
    final blockedUntil = DateTime.tryParse(prefValue)?.toLocal();
    if (_pinBlockedCountdown != null) {
      _pinBlockedCountdown.cancel();
      _pinBlockedCountdown = null;
    }

    final delta = blockedUntil != null ? blockedUntil.difference(DateTime.now()) : Duration.zero;
    if (delta.inSeconds > 2) {
      _pinBlockedCountdown = CountdownTimer(delta, const Duration(seconds: 1));
      _pinBlockedCountdown.map((cd) => cd.remaining).listen(_pinBlockedFor.add);
    } else {
      _pinBlockedFor.add(Duration.zero);
    }
  }

  Stream<Duration> getPinBlockedFor() {
    return _pinBlockedFor;
  }

  Future<bool> setPinBlockedUntil(DateTime value) {
    return StreamingSharedPreferences.instance.then((preferences) {
      return preferences.setString(_pinBlockedUntilKey, value.toUtc().toIso8601String());
    });
  }
}
