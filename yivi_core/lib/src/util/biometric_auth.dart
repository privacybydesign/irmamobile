import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:local_auth/error_codes.dart" as auth_error;
import "package:local_auth/local_auth.dart";
import "package:local_auth_android/local_auth_android.dart";
import "package:local_auth_darwin/types/auth_messages_ios.dart";

class BiometricAuthResult {
  final bool success;
  final bool cancelled;
  final bool unsupported;
  final String? errorCode;

  const BiometricAuthResult({
    required this.success,
    this.cancelled = false,
    this.unsupported = false,
    this.errorCode,
  });
}

class BiometricAuth {
  // Test hook: when set, every default `BiometricAuth()` constructor call
  // returns the factory result. Lets integration tests script biometric
  // outcomes without touching screens that construct BiometricAuth inline.
  @visibleForTesting
  static BiometricAuth Function()? overrideFactory;

  factory BiometricAuth({LocalAuthentication? auth}) {
    final override = overrideFactory;
    if (override != null) return override();
    return BiometricAuth.real(auth: auth);
  }

  BiometricAuth.real({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  @visibleForTesting
  BiometricAuth.forTesting() : _auth = null;

  final LocalAuthentication? _auth;

  Future<bool> canAuthenticate() async {
    final auth = _auth;
    if (auth == null) return false;
    try {
      final isSupported = await auth.isDeviceSupported();
      if (!isSupported) return false;
      return auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  Future<BiometricAuthResult> authenticate({
    required String reason,
    required String androidSignInTitle,
    required String androidCancelButton,
    required String iosCancelButton,
    required String iosLockoutMessage,
  }) async {
    final auth = _auth;
    if (auth == null) {
      return const BiometricAuthResult(success: false, unsupported: true);
    }
    try {
      // Android maps `localizedReason` to `BiometricPrompt.setDescription`,
      // which renders as a third line under title + subtitle. We already
      // show "Open Yivi" as the title, so a duplicate description is just
      // visual noise. local_auth_android asserts `localizedReason.isNotEmpty`,
      // so we can't fully omit it — pass a single space, which keeps the
      // dialog row blank and lets the title carry the message.
      // On iOS `localizedReason` IS the main prompt text and must be
      // meaningful and non-empty, so we keep it there.
      final localizedReason = Platform.isAndroid ? " " : reason;
      final ok = await auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          // Force biometric-only so the OS won't offer its device PIN /
          // passcode fallback — Yivi has its own PIN and showing the device
          // passcode prompt next to it would be confusing.
          biometricOnly: true,
        ),
        authMessages: [
          AndroidAuthMessages(
            signInTitle: androidSignInTitle,
            cancelButton: androidCancelButton,
            // Empty subtitle hides the "Verify identity" row that
            // local_auth_android defaults to. BiometricPrompt sets the
            // subtitle view's visibility to GONE when the string is empty.
            biometricHint: "",
          ),
          IOSAuthMessages(
            cancelButton: iosCancelButton,
            lockOut: iosLockoutMessage,
          ),
        ],
      );
      return BiometricAuthResult(success: ok, cancelled: !ok);
    } on PlatformException catch (e) {
      final unsupported =
          e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled ||
          e.code == auth_error.passcodeNotSet;
      return BiometricAuthResult(
        success: false,
        cancelled: false,
        unsupported: unsupported,
        errorCode: e.code,
      );
    }
  }
}
