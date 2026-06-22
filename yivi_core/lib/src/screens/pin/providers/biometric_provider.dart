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

  /// Shows the OS biometric prompt and returns whether it succeeded. No side
  /// effects — used to confirm the user can authenticate before persisting
  /// `enabled = true` (enrollment, the opt-in dialog, the Settings toggle).
  /// [localizedReason] is shown in the OS prompt.
  Future<bool> authenticate({required String localizedReason}) async {
    final auth = _ref.read(localAuthProvider);
    try {
      return await auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
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
