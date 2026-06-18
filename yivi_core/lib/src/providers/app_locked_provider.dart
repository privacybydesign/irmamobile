import "package:flutter_riverpod/flutter_riverpod.dart";

import "irma_repository_provider.dart";

/// Bridges `repo.getLocked()` to a Riverpod Notifier so consumers can
/// `ref.watch` instead of building a StreamBuilder. Same shape as
/// [SessionAwaitingInteractionNotifier] in `session_state_provider.dart`:
/// a Notifier that subscribes to a stream and mirrors the latest value.
///
/// The initial value is `true` ("lock by default") — `_lockedSubject`
/// in the repo is itself seeded `true`, so the subscription will
/// confirm it on the first emission. Treating "unknown" as locked is
/// the safe choice if anything ever races.
class AppLockedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final repo = ref.watch(irmaRepositoryProvider);
    final sub = repo.getLocked().listen((v) => state = v);
    ref.onDispose(sub.cancel);
    return true;
  }
}

final appLockedProvider = NotifierProvider<AppLockedNotifier, bool>(
  AppLockedNotifier.new,
);
