import "package:flutter_riverpod/flutter_riverpod.dart";

import "irma_repository_provider.dart";

/// Mirrors `repo.getHasInFlightSession()`: `true` while a session is running
/// (started, not yet terminal), `false` otherwise.
///
/// The lock-screen [PinScreen] watches this to withhold its biometric surfaces
/// while a session is in flight. This covers the case the pending-pointer gate
/// misses: when the app was unlocked as it went to the background, a link
/// arriving then is consumed into a *session* immediately (clearing the pending
/// pointer) — and only afterwards does the idle-lock re-lock on resume. By that
/// point there is no pending pointer, but there is an in-flight session, which
/// needs the (idle-lock-cleared) keyshare token and so must be admitted only by
/// a PIN, never biometric (issue #654). Tracked from session start rather than
/// the first `requestPermission` state so it is true before Go replies.
class HasInFlightSessionNotifier extends Notifier<bool> {
  @override
  bool build() {
    final repo = ref.watch(irmaRepositoryProvider);
    final sub = repo.getHasInFlightSession().listen((v) => state = v);
    ref.onDispose(sub.cancel);
    return repo.hasInFlightSession;
  }
}

final hasInFlightSessionProvider =
    NotifierProvider<HasInFlightSessionNotifier, bool>(
      HasInFlightSessionNotifier.new,
    );
