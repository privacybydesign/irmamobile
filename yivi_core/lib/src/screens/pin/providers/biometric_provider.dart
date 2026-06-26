import "dart:io";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:local_auth/local_auth.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../providers/preferences_provider.dart";
import "../../../util/privacy_screen.dart";

/// The local_auth entry point, behind a provider so tests can override it.
final localAuthProvider = Provider<LocalAuthentication>(
  (ref) => LocalAuthentication(),
);

/// Whether this device supports biometrics AND has at least one enrolled.
/// Any failure (unsupported, none enrolled, OS denies, plugin missing) maps to
/// `false` — the UI then hides the biometric button and Settings toggle and
/// the app falls back to PIN unlock.
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final auth = ref.watch(localAuthProvider);
  try {
    if (!await auth.isDeviceSupported()) return false;
    final canCheck = await auth.canCheckBiometrics;
    final enrolled = await auth.getAvailableBiometrics();
    return canCheck && enrolled.isNotEmpty;
  } catch (_) {
    return false;
  }
});

/// The device's primary enrolled biometric type — face for Face ID / face
/// unlock, fingerprint for Touch ID and fingerprint sensors, null if none or
/// only Android's generic strong/weak (where the OS hides the sensor). The UI
/// maps this to an icon. Differs per platform for free — iOS reports `face`
/// for Face ID and `fingerprint` for Touch ID.
final biometricTypeProvider = FutureProvider<BiometricType?>((ref) async {
  final auth = ref.watch(localAuthProvider);
  try {
    final enrolled = await auth.getAvailableBiometrics();
    if (enrolled.contains(BiometricType.face)) return BiometricType.face;
    if (enrolled.contains(BiometricType.fingerprint)) {
      return BiometricType.fingerprint;
    }
  } catch (_) {}
  return null;
});

/// Whether the user opted in to biometric unlock (pref-backed, default off).
final biometricEnabledProvider = StreamProvider<bool>(
  (ref) => ref.watch(preferencesProvider).getBiometricEnabled(),
);

/// Whether the biometric scan fires automatically when the lock screen appears
/// (pref-backed, default on). Only matters while [biometricEnabledProvider].
final biometricImmediateProvider = StreamProvider<bool>(
  (ref) => ref.watch(preferencesProvider).getBiometricImmediate(),
);

/// Whether the one-time opt-in prompt has already been answered/dismissed.
final biometricPromptDismissedProvider = StreamProvider<bool>(
  (ref) => ref.watch(preferencesProvider).getBiometricPromptDismissed(),
);

/// Biometric actions. A successful prompt only flips the local `appLocked`
/// flag via [IrmaRepository.unlockAppLocally] — it never authenticates against
/// the keyshare server, so the first session afterwards still requires the
/// PIN. (Storing the PIN for a biometric-gated keyshare unlock is deliberately
/// not done.)
class BiometricService {
  BiometricService(this._ref);
  final Ref _ref;

  /// Shows the OS biometric prompt and returns whether it succeeded. No side
  /// effects — used to confirm the user can authenticate before persisting
  /// `enabled = true` (enrollment, the opt-in dialog, the Settings toggle).
  /// [localizedReason] is shown in the OS prompt.
  Future<bool> authenticate({required String localizedReason}) async {
    final auth = _ref.read(localAuthProvider);
    // The OS biometric prompt makes the app resign-active. On iOS that fires
    // the privacy-screen blur, which then covers the whole screen for the full
    // duration of the Face ID scan (it's only removed once the app becomes
    // active again) — making Face ID look slow behind a lingering blur.
    // Suppress it around the prompt and restore the user's screenshot/privacy
    // preference afterwards. iOS-only: Android's privacy screen is FLAG_SECURE
    // (no visible blur), so there's nothing to suppress and clearing it would
    // needlessly drop the flag mid-prompt.
    final suppressPrivacyScreen = Platform.isIOS;
    try {
      if (suppressPrivacyScreen) await PrivacyScreen.disablePrivacyScreen();
      return await auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true, // was stickyAuth in local_auth <3
      );
    } catch (_) {
      return false;
    } finally {
      if (suppressPrivacyScreen) await _restorePrivacyScreen();
    }
  }

  /// Re-enable the privacy-screen blur unless the user has screenshots enabled.
  /// Mirrors the app-level screenshot-pref listener so we end up in whatever
  /// state the user configured, regardless of how the prompt resolved.
  Future<void> _restorePrivacyScreen() async {
    final screenshotsEnabled = await _ref
        .read(preferencesProvider)
        .getScreenshotsEnabled()
        .first;
    if (!screenshotsEnabled) await PrivacyScreen.enablePrivacyScreen();
  }

  /// Lock-screen biometric button: authenticate and, on success, unlock the
  /// app shell locally (no keyshare — sessions still require the PIN).
  Future<bool> authenticateAndUnlock({required String localizedReason}) async {
    final didAuthenticate = await authenticate(
      localizedReason: localizedReason,
    );
    if (didAuthenticate) {
      _ref.read(irmaRepositoryProvider).unlockAppLocally();
    }
    return didAuthenticate;
  }

  Future<void> setEnabled(bool value) =>
      _ref.read(preferencesProvider).setBiometricEnabled(value);

  Future<void> dismissPrompt() =>
      _ref.read(preferencesProvider).setBiometricPromptDismissed(true);
}

final biometricServiceProvider = Provider<BiometricService>(
  BiometricService.new,
);
