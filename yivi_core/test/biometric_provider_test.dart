import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:local_auth/local_auth.dart";
import "package:yivi_core/src/screens/pin/providers/biometric_provider.dart";

class _FakeLocalAuth implements LocalAuthentication {
  _FakeLocalAuth({
    this.supported = true,
    this.canCheck = true,
    this.enrolled = const [BiometricType.fingerprint],
    this.error = false,
  });

  final bool supported;
  final bool canCheck;
  final List<BiometricType> enrolled;
  final bool error;

  @override
  Future<bool> isDeviceSupported() async {
    if (error) throw PlatformException(code: "err");
    return supported;
  }

  @override
  Future<bool> get canCheckBiometrics async => canCheck;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => enrolled;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<bool> available(LocalAuthentication auth) {
  final container = ProviderContainer(
    overrides: [localAuthProvider.overrideWithValue(auth)],
  );
  addTearDown(container.dispose);
  return container.read(biometricAvailableProvider.future);
}

void main() {
  test(
    "available when supported, can check, and a biometric is enrolled",
    () async {
      expect(await available(_FakeLocalAuth()), true);
    },
  );

  test("unavailable when the device is unsupported", () async {
    expect(await available(_FakeLocalAuth(supported: false)), false);
  });

  test("unavailable when no biometrics are enrolled", () async {
    expect(await available(_FakeLocalAuth(enrolled: [])), false);
  });

  test("unavailable when biometrics cannot be checked", () async {
    expect(await available(_FakeLocalAuth(canCheck: false)), false);
  });

  test("unavailable (not an error) when the platform check throws", () async {
    expect(await available(_FakeLocalAuth(error: true)), false);
  });
}
