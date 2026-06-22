import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:local_auth/local_auth.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../providers/preferences_provider.dart";

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

/// Whether the user opted in to biometric unlock (pref-backed, default off).
final biometricEnabledProvider = StreamProvider<bool>(
  (ref) => ref.watch(preferencesProvider).getBiometricEnabled(),
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

  /// Shows the OS biometric prompt. On success unlocks the app shell locally
  /// and returns `true`; on failure/cancel returns `false` and the user stays
  /// on the PIN screen. [localizedReason] is shown in the OS prompt.
  Future<bool> authenticateAndUnlock({required String localizedReason}) async {
    final auth = _ref.read(localAuthProvider);
    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (didAuthenticate) {
        _ref.read(irmaRepositoryProvider).unlockAppLocally();
      }
      return didAuthenticate;
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool value) =>
      _ref.read(preferencesProvider).setBiometricEnabled(value);

  Future<void> dismissPrompt() =>
      _ref.read(preferencesProvider).setBiometricPromptDismissed(true);
}

final biometricServiceProvider = Provider<BiometricService>(
  BiometricService.new,
);
