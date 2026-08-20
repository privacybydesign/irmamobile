import "package:flutter_riverpod/flutter_riverpod.dart";

import "irma_repository_provider.dart";

/// Mirrors `repo.getStartupUrlResolved()`: `false` until native acknowledges the
/// launch handshake, `true` afterwards. The lock-screen [PinScreen] gates its
/// cold-start biometric auto-scan on this so biometric can't win the race
/// against a universal link and unlock the app before the session pointer that
/// launched it is known — which would otherwise let a link session ride in on a
/// biometric-only unlock (issue #644).
class StartupUrlResolvedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final repo = ref.watch(irmaRepositoryProvider);
    final sub = repo.getStartupUrlResolved().listen((v) => state = v);
    ref.onDispose(sub.cancel);
    return false;
  }
}

final startupUrlResolvedProvider =
    NotifierProvider<StartupUrlResolvedNotifier, bool>(
      StartupUrlResolvedNotifier.new,
    );
