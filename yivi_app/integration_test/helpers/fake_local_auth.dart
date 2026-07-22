import "dart:async";

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

  /// Number of times `authenticate()` was invoked — lets tests assert the
  /// auto-scan fires exactly once (no re-prompt loop).
  int authenticateCalls = 0;

  /// When set, `authenticate()` waits on this future instead of returning
  /// immediately, so a test can hold the "prompt" on screen, inject state (e.g.
  /// a pointer arriving mid-prompt), then release it by completing the gate.
  /// Null (the default) means `authenticate()` resolves at once.
  Completer<bool>? authenticateGate;

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
      authenticateCalls++;
      final gate = authenticateGate;
      if (gate != null) return gate.future;
      return Future<bool>.value(authenticateResult);
    }
    return super.noSuchMethod(invocation);
  }
}
