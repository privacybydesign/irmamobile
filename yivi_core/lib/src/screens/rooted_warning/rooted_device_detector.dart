import "dart:io";

import "package:jailbreak_root_detection/jailbreak_root_detection.dart";

abstract class RootedDeviceDetector {
  Future<bool> isDeviceRooted();
}

class RealRootedDeviceDetector implements RootedDeviceDetector {
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
