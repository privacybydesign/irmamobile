import 'dart:io';

import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';

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
  Future<bool> isDeviceRooted() async {
    final isJailBroken = await JailbreakRootDetection.instance.isJailBroken;

    // On ios we add the check for simulators, so the warning doesn't show in simulators
    if (Platform.isIOS) {
      return isJailBroken && await JailbreakRootDetection.instance.isRealDevice;
    }

    return isJailBroken;
  }
}
