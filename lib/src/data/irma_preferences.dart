import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:rxdart/subjects.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

class IrmaPreferences {
  static IrmaPreferences _instance;

  static IrmaPreferences get() {
    return _instance ??= IrmaPreferences._internal();
  }

  IrmaPreferences._internal() {
    StreamingSharedPreferences.instance.then((preferences) {
      final startQRScanPref = preferences.getBool(_startQRScanKey, defaultValue: false);
      startQRScanPref.listen(_startQRScan.add);

      final showDisclosureDialogPref = preferences.getBool(_showDisclosureDialogKey, defaultValue: true);
      showDisclosureDialogPref.listen(_showDisclosureDialog.add);
    });
  }

  Stream<bool> getReportErrors() {
    return IrmaRepository.get().getPreferences().map((p) => p.enableCrashReporting);
  }

  void setReportErrors(bool value) {
    IrmaRepository.get().dispatch(SetCrashReportingPreferenceEvent(enableCrashReporting: value), isBridgedEvent: true);
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
}
