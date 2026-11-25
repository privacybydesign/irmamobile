import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/irma_preferences.dart";
import "../data/pref.dart";

final preferencesProvider = Provider<IrmaPreferences>(
  (ref) => throw UnimplementedError(
    "should be overwritten in main, so we don't have to make it async",
  ),
);

/// One stored preference as a provider: its value from the first read on,
/// following every change.
class PrefNotifier<T> extends Notifier<T> {
  PrefNotifier(this._pick);

  final Pref<T> Function(IrmaPreferences prefs) _pick;
  late Pref<T> _pref;

  @override
  T build() {
    _pref = _pick(ref.watch(preferencesProvider));
    final sub = _pref.stream.listen((value) => state = value);
    ref.onDispose(sub.cancel);
    return _pref.value;
  }

  /// Stores [value]; the provider follows when the store has it.
  Future<bool> set(T value) => _pref.set(value);
}

/// A provider over the preference [pick] chooses.
NotifierProvider<PrefNotifier<T>, T> prefProvider<T>(
  Pref<T> Function(IrmaPreferences prefs) pick,
) => NotifierProvider<PrefNotifier<T>, T>(() => PrefNotifier(pick));

/// Whether the user opted for a 16-digit PIN (vs the default 5-digit).
final longPinProvider = prefProvider((p) => p.longPin);

/// Whether the user opted in to biometric unlock (default off).
final biometricEnabledProvider = prefProvider((p) => p.biometricEnabled);

/// Whether the biometric scan fires automatically when the lock screen
/// appears (default on). Only matters while [biometricEnabledProvider].
final biometricImmediateProvider = prefProvider((p) => p.biometricImmediate);

/// Whether the one-time opt-in prompt has already been answered/dismissed.
final biometricPromptDismissedProvider = prefProvider(
  (p) => p.biometricPromptDismissed,
);

/// Set when the enrollment completes, until the Scan button was pointed out.
final scanTipPendingProvider = prefProvider((p) => p.scanTipPending);

/// Whether this install has linked an e-mail address.
final emailLinkedProvider = prefProvider((p) => p.emailLinked);

/// Whether "Success" offered to secure the app once already.
final secureOfferShownProvider = prefProvider((p) => p.secureOfferShown);

/// The local backend host set in the debug menu; empty for the real ones.
final localBackendHostProvider = prefProvider((p) => p.localBackendHost);

/// The language the user picked; empty follows the system language.
final preferredLanguageCodeProvider = prefProvider(
  (p) => p.preferredLanguageCode,
);

/// Whether error reports are sent.
final reportErrorsProvider = prefProvider((p) => p.reportErrors);

/// Whether screenshots are allowed (Android).
final screenshotsEnabledProvider = prefProvider((p) => p.screenshotsEnabled);

/// Light, dark or the system's.
final appearanceProvider = prefProvider((p) => p.appearance);

/// The PIN-visible preference itself, for the PIN screen, which reads it
/// once and writes it on a tap.
final pinVisiblePrefProvider = Provider<Pref<bool>>(
  (ref) => ref.watch(preferencesProvider).pinVisible,
);
