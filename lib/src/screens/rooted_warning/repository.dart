import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

import '../../data/irma_preferences.dart';

abstract class DetectRootedDeviceRepository {
  Stream<bool> hasAcceptedRootedDeviceRisk();
  Future<void> setHasAcceptedRootedDeviceRisk();
  Future<bool> isDeviceRooted();
}

class DetectRootedDeviceIrmaPrefsRepository implements DetectRootedDeviceRepository {
  final IrmaPreferences _preferences;

  DetectRootedDeviceIrmaPrefsRepository({required IrmaPreferences preferences}) : _preferences = preferences;

  @override
  Stream<bool> hasAcceptedRootedDeviceRisk() {
    return _preferences.getAcceptedRootedRisk();
  }

  @override
  Future<void> setHasAcceptedRootedDeviceRisk() async {
    _preferences.setAcceptedRootedRisk(true);
  }

  @override
  Future<bool> isDeviceRooted() {
    return FlutterJailbreakDetection.jailbroken;
  }
}
