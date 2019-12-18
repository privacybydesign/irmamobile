import 'dart:async';

import 'irma_app_settings.dart';


class IrmaSettingsMock implements IrmaAppSettings {
  IrmaSettingsMock()
    : _startQRScan = false,
      _reportErrors = false,
      _experimentalData = false
  {
    _startQRScanStream = StreamController.broadcast(
      onListen: () => _startQRScanStream.add(_startQRScan)
    );

    _reportErrorsStream = StreamController.broadcast(
      onListen: () => _reportErrorsStream.add(_reportErrors)
    );

    _experimentalDataStream = StreamController.broadcast(
      onListen: () => _experimentalDataStream.add(_experimentalData)
    );
  }

  @override
  Stream<bool> getStartQRScan() {
    return _startQRScanStream.stream;
  }

  @override
  Future<bool> setStartQRScan(bool value) {
    _startQRScan = value;
    _startQRScanStream.add(_startQRScan);
    return Future.value(_startQRScan);
  }

  @override
  Stream<bool> getReportErrors() {
    return _reportErrorsStream.stream;
  }

  @override
  Future<bool> setReportErrors(bool value) {
    _reportErrors = value;
    _reportErrorsStream.add(_reportErrors);
    return Future.value(_reportErrors);
  }

  @override
  Stream<bool> getExperimentalData() {
    return _experimentalDataStream.stream;
  }

  @override
  Future<bool> setExperimentalData(bool value) {
    _experimentalData = value;
    _experimentalDataStream.add(_experimentalData);
    return Future.value(_experimentalData);
  }

  StreamController<bool> _startQRScanStream;
  bool _startQRScan;

  StreamController<bool> _reportErrorsStream;
  bool _reportErrors;

  StreamController<bool> _experimentalDataStream;
  bool _experimentalData;
}