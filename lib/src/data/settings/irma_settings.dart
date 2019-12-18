import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

import 'irma_app_settings.dart';


class IrmaSettings implements IrmaAppSettings {
  static IrmaAppSettings _instance;
  static IrmaAppSettings get() {
    if (_instance == null) {
      throw Exception("IrmaAppSettings has not been initialized");
    }
    return _instance;
  }

  IrmaSettings(StreamingSharedPreferences preferences)
    : _startQRScan = preferences.getBool('startQRScan', defaultValue: false),
      _reportErrors = preferences.getBool('reportErrors', defaultValue: false),
      _experimentalData = preferences.getBool('experimentalData', defaultValue: false);

  @override
  Stream<bool> getStartQRScan() {
    return _startQRScan;
  }

  @override
  Future<bool> setStartQRScan(bool value) {
    return _startQRScan.setValue(value);
  }

  @override
  Stream<bool> getReportErrors() {
    return _reportErrors;
  }

  @override
  Future<bool> setReportErrors(bool value) {
    return _reportErrors.setValue(value);
  }

  @override
  Stream<bool> getExperimentalData() {
    return _experimentalData;
  }

  @override
  Future<bool> setExperimentalData(bool value) {
    return _experimentalData.setValue(value);
  }

  final Preference<bool> _startQRScan;
  final Preference<bool> _reportErrors;
  final Preference<bool> _experimentalData;
}