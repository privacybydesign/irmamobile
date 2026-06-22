import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../models/authentication_events.dart";
import "../../../models/session.dart";
import "../../../providers/irma_repository_provider.dart";

/// App-unlock authentication state. Replaces the old `PinBloc`: a single
/// [Notifier] holds the auth state, [unlock] talks to the keyshare server,
/// and the blocked countdown lives in [pinBlockedForProvider] instead of a
/// manual `CountdownTimer` + `BehaviorSubject`.
@immutable
class PinUnlockState {
  final bool authenticated;
  final bool authenticateInProgress;
  final bool pinInvalid;
  final DateTime? blockedUntil;
  final int? remainingAttempts;
  final SessionError? error;

  const PinUnlockState({
    this.authenticated = false,
    this.authenticateInProgress = false,
    this.pinInvalid = false,
    this.blockedUntil,
    this.remainingAttempts,
    this.error,
  });
}

class PinUnlockNotifier extends Notifier<PinUnlockState> {
  @override
  PinUnlockState build() {
    final repo = ref.watch(irmaRepositoryProvider);

    // Reset to a clean locked state whenever irmago reports the app locked,
    // but keep any active server-side block (so locking can't race the
    // getBlockTime() seed below into clearing a real block).
    final sub = repo.getLocked().listen((locked) {
      if (locked) state = PinUnlockState(blockedUntil: state.blockedUntil);
    });
    ref.onDispose(sub.cancel);

    // Seed blocked-until if the keyshare server already has us blocked.
    repo.getBlockTime().first.then((blockedUntil) {
      if (blockedUntil != null) {
        state = PinUnlockState(blockedUntil: blockedUntil);
      }
    });

    return const PinUnlockState();
  }

  Future<void> unlock(String pin) async {
    if (state.authenticateInProgress) return;
    final repo = ref.read(irmaRepositoryProvider);

    state = const PinUnlockState(authenticateInProgress: true);

    final event = await repo.unlock(pin);
    state = switch (event) {
      AuthenticationSuccessEvent() => const PinUnlockState(authenticated: true),
      // To have some timing slack we add some time to the blocked duration.
      AuthenticationFailedEvent(
        :final remainingAttempts,
        :final blockedDuration,
      )
          when blockedDuration > 0 =>
        PinUnlockState(
          pinInvalid: true,
          remainingAttempts: remainingAttempts,
          blockedUntil: DateTime.now().add(
            Duration(seconds: blockedDuration + 5),
          ),
        ),
      AuthenticationFailedEvent(:final remainingAttempts) => PinUnlockState(
        pinInvalid: true,
        remainingAttempts: remainingAttempts,
      ),
      AuthenticationErrorEvent(:final error) => PinUnlockState(error: error),
      _ => throw Exception("Unexpected subtype of AuthenticationResult"),
    };
  }
}

final pinUnlockProvider = NotifierProvider<PinUnlockNotifier, PinUnlockState>(
  PinUnlockNotifier.new,
);

/// Seconds remaining until the PIN can be tried again, ticking down once a
/// second. Derived from [PinUnlockState.blockedUntil] — recomputed (and the
/// old ticker cancelled) whenever the block changes.
final pinBlockedForProvider = StreamProvider.autoDispose<Duration>((
  ref,
) async* {
  final blockedUntil = ref.watch(
    pinUnlockProvider.select((s) => s.blockedUntil),
  );
  if (blockedUntil == null) {
    yield Duration.zero;
    return;
  }
  while (true) {
    final remaining = blockedUntil.difference(DateTime.now());
    if (remaining.inSeconds <= 0) {
      yield Duration.zero;
      return;
    }
    yield remaining;
    await Future<void>.delayed(const Duration(seconds: 1));
  }
});
