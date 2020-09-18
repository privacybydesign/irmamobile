import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';

abstract class DetectRootedDeviceRepository {
  Stream<bool> hasAcceptedRootedDeviceRisk();
  Future<void> setHasAcceptedRootedDeviceRisk();
  Future<bool> isDeviceRooted();
}

class DetectRootedDeviceIrmaPrefsRepository implements DetectRootedDeviceRepository {
  @override
  Stream<bool> hasAcceptedRootedDeviceRisk() {
    final irmaPrefs = IrmaPreferences.get();
    return irmaPrefs.getAcceptedRootedRisk();
  }

  @override
  Future<void> setHasAcceptedRootedDeviceRisk() async {
    final irmaPrefs = IrmaPreferences.get();
    irmaPrefs.setAcceptedRootedRisk(true);
  }

  @override
  Future<bool> isDeviceRooted() {
    return FlutterJailbreakDetection.jailbroken;
  }
}
