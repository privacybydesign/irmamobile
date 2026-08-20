import "package:yivi_core/src/screens/rooted_warning/rooted_device_detector.dart";

class FakeRootedDeviceDetector implements RootedDeviceDetector {
  final bool rooted;

  const FakeRootedDeviceDetector({required this.rooted});

  @override
  Future<bool> isDeviceRooted() async => rooted;
}
