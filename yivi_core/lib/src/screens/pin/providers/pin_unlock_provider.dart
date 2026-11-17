import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../models/authentication_events.dart";
import "../../../models/session.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../util/haptics.dart";
import "../pin_feedback.dart";

/// App-unlock authentication state. Replaces the old `PinBloc`: a single
/// [Notifier] holds the auth state, [unlock] talks to the keyshare server,
/// and the blocked countdown lives in pinCountdownProvider instead of a
/// manual `CountdownTimer` + `BehaviorSubject`.
@immutable
class PinUnlockState {
  final bool authenticated;
  final bool authenticateInProgress;
  final bool pinInvalid;
  final DateTime? blockedUntil;
  final int? remainingAttempts;
  final SessionError? error;

  /// One more with every wrong PIN: the pad starts empty again.
  final int wrongCount;

  const PinUnlockState({
    this.authenticated = false,
    this.authenticateInProgress = false,
    this.pinInvalid = false,
    this.blockedUntil,
    this.remainingAttempts,
    this.error,
    this.wrongCount = 0,
  });

  /// What the pad shows of this.
  PinFeedback get feedback => PinFeedback(
    wrongCount: wrongCount,
    wrong: pinInvalid,
    left: remainingAttempts,
    blockedUntil: blockedUntil,
    busy: authenticateInProgress,
  );
}

class PinUnlockNotifier extends Notifier<PinUnlockState> {
  @override
  PinUnlockState build() {
    final repo = ref.watch(irmaRepositoryProvider);

    // Reset to a clean locked state whenever irmago reports the app locked,
    // but keep any active server-side block (so locking can't race the
    // getBlockTime() seed below into clearing a real block).
    final sub = repo.getLocked().listen((locked) {
      if (locked) {
        state = PinUnlockState(
          blockedUntil: state.blockedUntil,
          wrongCount: state.wrongCount,
        );
      }
    });
    ref.onDispose(sub.cancel);

    // Seed blocked-until if the keyshare server already has us blocked.
    // A cancel-on-dispose subscription (cancelled after the first value),
    // not a fire-and-forget `.first`: getBlockTime() is an unseeded subject
    // that never emits during enrollment, so a pending `.first` throws
    // "Bad state: No element" when the repo is closed (test teardown) before
    // any block arrives.
    StreamSubscription<DateTime?>? blockSub;
    blockSub = repo.getBlockTime().listen((blockedUntil) {
      blockSub?.cancel();
      blockSub = null;
      if (blockedUntil != null) {
        state = PinUnlockState(
          blockedUntil: blockedUntil,
          wrongCount: state.wrongCount,
        );
      }
    });
    ref.onDispose(() => blockSub?.cancel());

    return const PinUnlockState();
  }

  Future<void> unlock(String pin) async {
    if (state.authenticateInProgress) return;
    final repo = ref.read(irmaRepositoryProvider);

    final wrongCount = state.wrongCount;
    state = PinUnlockState(
      authenticateInProgress: true,
      wrongCount: wrongCount,
    );

    final event = await repo.unlock(pin);
    state = switch (event) {
      AuthenticationSuccessEvent() => PinUnlockState(
        authenticated: true,
        wrongCount: wrongCount,
      ),
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
          wrongCount: wrongCount + 1,
        ),
      AuthenticationFailedEvent(:final remainingAttempts) => PinUnlockState(
        pinInvalid: true,
        remainingAttempts: remainingAttempts,
        wrongCount: wrongCount + 1,
      ),
      AuthenticationErrorEvent(:final error) => PinUnlockState(
        error: error,
        wrongCount: wrongCount,
      ),
      _ => throw Exception("Unexpected subtype of AuthenticationResult"),
    };
    // Here, where the answer arrives: a pad shown twice (the lock screen
    // under the scanner sheet) buzzes once.
    if (state.authenticated) {
      Haptics.success();
    } else {
      Haptics.error();
    }
  }
}

final pinUnlockProvider = NotifierProvider<PinUnlockNotifier, PinUnlockState>(
  PinUnlockNotifier.new,
);
