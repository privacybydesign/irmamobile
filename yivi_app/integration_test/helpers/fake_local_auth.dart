import "package:local_auth/local_auth.dart";

/// Test double for [LocalAuthentication] so biometric flows can be driven
/// without the real OS prompt. [available] controls the availability checks;
/// [authenticateResult] is what `authenticate()` returns. `authenticate` is
/// handled via [noSuchMethod] to avoid depending on the `AuthMessages` type
/// (which the `local_auth` barrel does not re-export).
class FakeLocalAuthentication implements LocalAuthentication {
  FakeLocalAuthentication({
    this.available = true,
    this.authenticateResult = true,
  });

  final bool available;
  final bool authenticateResult;

  @override
  Future<bool> isDeviceSupported() async => available;

  @override
  Future<bool> get canCheckBiometrics async => available;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async =>
      available ? const [BiometricType.fingerprint] : const [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #authenticate) {
      return Future<bool>.value(authenticateResult);
    }
    return super.noSuchMethod(invocation);
  }
}
