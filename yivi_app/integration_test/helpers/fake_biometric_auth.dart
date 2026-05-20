import "package:yivi_core/src/util/biometric_auth.dart";

/// Fake [BiometricAuth] for integration tests.
///
/// Lets tests script `canAuthenticate()` (does the device claim support?) and
/// `authenticate()` (what does the OS prompt return?) without ever touching
/// the platform `local_auth` channel.
///
/// Install it via [BiometricAuth.overrideFactory] in `setUp` and clear it in
/// `tearDown`. See [install] / [clearOverride].
class FakeBiometricAuth extends BiometricAuth {
  bool supported;
  BiometricAuthResult nextResult;
  int authenticateCalls = 0;
  int canAuthenticateCalls = 0;

  FakeBiometricAuth({
    this.supported = true,
    BiometricAuthResult? result,
  }) : nextResult = result ?? const BiometricAuthResult(success: true),
       super.forTesting();

  /// Install this fake as the global `BiometricAuth()` factory override.
  /// Returns the fake so tests can reconfigure it mid-test.
  static FakeBiometricAuth install({
    bool supported = true,
    BiometricAuthResult? result,
  }) {
    final fake = FakeBiometricAuth(supported: supported, result: result);
    BiometricAuth.overrideFactory = () => fake;
    return fake;
  }

  static void clearOverride() {
    BiometricAuth.overrideFactory = null;
  }

  @override
  Future<bool> canAuthenticate() async {
    canAuthenticateCalls++;
    return supported;
  }

  @override
  Future<BiometricAuthResult> authenticate({
    required String reason,
    required String androidSignInTitle,
    required String androidCancelButton,
    required String iosCancelButton,
    required String iosLockoutMessage,
  }) async {
    authenticateCalls++;
    return nextResult;
  }
}
