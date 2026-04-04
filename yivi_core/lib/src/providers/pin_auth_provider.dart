import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:quiver/async.dart";
import "package:rxdart/subjects.dart";

import "../models/authentication_events.dart";
import "../models/session.dart";
import "../models/session_events.dart";
import "irma_repository_provider.dart";

final pinAuthProvider =
    NotifierProvider.autoDispose<PinAuthNotifier, PinAuthState>(
      PinAuthNotifier.new,
    );

class PinAuthState {
  final bool authenticated;
  final bool authenticateInProgress;
  final DateTime? blockedUntil;
  final bool pinInvalid;
  final SessionError? error;
  final int? remainingAttempts;

  const PinAuthState({
    this.authenticated = false,
    this.authenticateInProgress = false,
    this.blockedUntil,
    this.pinInvalid = false,
    this.error,
    this.remainingAttempts,
  });
}

class PinAuthNotifier extends Notifier<PinAuthState> {
  late final BehaviorSubject<Duration> _pinBlockedFor;
  CountdownTimer? _pinBlockedCountdown;

  @override
  PinAuthState build() {
    _pinBlockedFor = BehaviorSubject<Duration>();
    final repo = ref.read(irmaRepositoryProvider);
    final sub = repo.getLocked().listen((isLocked) {
      if (isLocked) state = const PinAuthState();
    });
    ref.onDispose(() {
      sub.cancel();
      _pinBlockedCountdown?.cancel();
      _pinBlockedFor.close();
    });
    return const PinAuthState();
  }

  Stream<Duration> getPinBlockedFor() => _pinBlockedFor;

  void setBlocked(DateTime blockedUntil) {
    _setPinBlockedUntil(blockedUntil);
    state = PinAuthState(
      pinInvalid: true,
      blockedUntil: blockedUntil,
      remainingAttempts: 0,
    );
  }

  Future<void> unlock(String pin) async {
    state = const PinAuthState(authenticateInProgress: true);
    final repo = ref.read(irmaRepositoryProvider);
    final authEvent = await repo.unlock(pin);
    _handleAuthResult(authEvent);
  }

  Future<void> authenticateSession(int sessionID, String pin) async {
    state = const PinAuthState(authenticateInProgress: true);
    final repo = ref.read(irmaRepositoryProvider);
    repo.bridgedDispatch(
      RespondPinEvent(sessionID: sessionID, pin: pin, proceed: true),
    );

    final event = await repo.getEvents().firstWhere((event) {
      return event is SessionEvent && event.sessionID == sessionID;
    });

    if (event is KeyshareBlockedSessionEvent) {
      _handleAuthResult(
        AuthenticationFailedEvent(
          remainingAttempts: 0,
          blockedDuration: event.duration,
        ),
      );
    } else if (event is RequestPinSessionEvent) {
      _handleAuthResult(
        AuthenticationFailedEvent(
          remainingAttempts: event.remainingAttempts,
          blockedDuration: 0,
        ),
      );
    } else {
      _handleAuthResult(AuthenticationSuccessEvent());
    }
  }

  void _handleAuthResult(AuthenticationEvent authEvent) {
    if (authEvent is AuthenticationSuccessEvent) {
      state = const PinAuthState(authenticated: true);
    } else if (authEvent is AuthenticationFailedEvent) {
      if (authEvent.blockedDuration > 0) {
        final blockedUntil = DateTime.now().add(
          Duration(seconds: authEvent.blockedDuration + 5),
        );
        _setPinBlockedUntil(blockedUntil);
        state = PinAuthState(
          pinInvalid: true,
          blockedUntil: blockedUntil,
          remainingAttempts: authEvent.remainingAttempts,
        );
      } else {
        state = PinAuthState(
          pinInvalid: true,
          remainingAttempts: authEvent.remainingAttempts,
        );
      }
    } else if (authEvent is AuthenticationErrorEvent) {
      state = PinAuthState(error: authEvent.error);
    }
  }

  void _setPinBlockedUntil(DateTime blockedUntil) {
    _pinBlockedCountdown?.cancel();
    _pinBlockedCountdown = null;

    final delta = blockedUntil.difference(DateTime.now());
    if (delta.inSeconds > 2) {
      _pinBlockedCountdown = CountdownTimer(delta, const Duration(seconds: 1));
      _pinBlockedCountdown!
          .map((cd) => cd.remaining)
          .listen(_pinBlockedFor.add);
    } else {
      _pinBlockedFor.add(Duration.zero);
    }
  }
}
