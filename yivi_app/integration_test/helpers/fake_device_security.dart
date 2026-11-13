import "package:yivi_core/src/screens/device_lock/device_security.dart";

/// Test devices and emulators often have no screen lock, so the integration
/// tests fake one unless a test asks for a device without it.
class FakeDeviceSecurity implements DeviceSecurity {
  final bool secure;

  const FakeDeviceSecurity({required this.secure});

  @override
  Future<bool> isDeviceSecure() async => secure;

  @override
  Future<void> openSecuritySettings() async {}
}
