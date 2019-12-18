


abstract class IrmaAppSettings {
  Stream<bool> getStartQRScan();
  Future<bool> setStartQRScan(bool value);

  Stream<bool> getReportErrors();
  Future<bool> setReportErrors(bool value);

  Stream<bool> getExperimentalData();
  Future<bool> setExperimentalData(bool value);
}