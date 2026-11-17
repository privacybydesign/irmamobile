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

/// Whether the e-mail banner was dismissed for good.
final emailBannerDismissedProvider = prefProvider(
  (p) => p.emailBannerDismissed,
);

/// Before when the e-mail banner stays hidden.
final emailBannerSnoozedUntilProvider = prefProvider(
  (p) => p.emailBannerSnoozedUntil,
);

/// The local backend host set in the debug menu; empty for the real ones.
final localBackendHostProvider = prefProvider((p) => p.localBackendHost);
