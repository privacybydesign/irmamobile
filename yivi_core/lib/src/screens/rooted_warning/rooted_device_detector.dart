import "package:flutter/services.dart";

abstract class RootedDeviceDetector {
  Future<bool> isDeviceRooted();
}

class RealRootedDeviceDetector implements RootedDeviceDetector {
  static const _channel = MethodChannel("yivi.app/root_detection");

  @override
  Future<bool> isDeviceRooted() async =>
      await _channel.invokeMethod<bool>("isDeviceRooted") ?? false;
}
