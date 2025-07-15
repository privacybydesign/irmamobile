import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quiver/async.dart';
import 'package:rxdart/subjects.dart';

import '../../../data/irma_repository.dart';
import '../../../models/authentication_events.dart';
import 'pin_event.dart';
import 'pin_state.dart';

class PinBloc extends Bloc<PinEvent, PinState> {
  final BehaviorSubject<Duration> _pinBlockedFor = BehaviorSubject<Duration>();

  late final StreamSubscription? _lockedStreamSubscription;
  CountdownTimer? _pinBlockedCountdown;

  PinBloc(IrmaRepository repo) : super(PinBloc._initialState) {
    _lockedStreamSubscription = repo.getLocked().listen((isLocked) {
      if (isLocked) {
        add(Locked());
      }
    });
  }

  @override
  Future<void> close() async {
    _lockedStreamSubscription?.cancel();
    return super.close();
  }

  static PinState get _initialState => PinState();

  @override
  Stream<PinState> mapEventToState(PinEvent event) async* {
    if (event is Blocked) {
      setPinBlockedUntil(event.blockedUntil);
      yield PinState(pinInvalid: true, blockedUntil: event.blockedUntil, remainingAttempts: 0);
    } else if (event is Authenticate) {
      yield PinState(authenticateInProgress: true);

      final authenticationEvent = await event.dispatch();
      if (authenticationEvent is AuthenticationSuccessEvent) {
        yield PinState(authenticated: true);
      } else if (authenticationEvent is AuthenticationFailedEvent) {
        // To have some timing slack we add some time to the blocked duration.
        if (authenticationEvent.blockedDuration > 0) {
          final blockedUntil = DateTime.now().add(Duration(seconds: authenticationEvent.blockedDuration + 5));
          setPinBlockedUntil(blockedUntil);
          yield PinState(
            pinInvalid: true,
            blockedUntil: blockedUntil,
            remainingAttempts: authenticationEvent.remainingAttempts,
          );
        } else {
          yield PinState(pinInvalid: true, remainingAttempts: authenticationEvent.remainingAttempts);
        }
      } else if (authenticationEvent is AuthenticationErrorEvent) {
        yield PinState(error: authenticationEvent.error);
      } else {
        throw Exception('Unexpected subtype of AuthenticationResult');
      }
    } else if (event is Locked) {
      yield PinState();
    }
  }

  // Create derived stream that counts the seconds until pin can be used again.
  void setPinBlockedUntil(DateTime blockedUntil) {
    if (_pinBlockedCountdown != null) {
      _pinBlockedCountdown?.cancel();
      _pinBlockedCountdown = null;
    }

    final delta = blockedUntil.difference(DateTime.now());
    if (delta.inSeconds > 2) {
      _pinBlockedCountdown = CountdownTimer(delta, const Duration(seconds: 1));
      _pinBlockedCountdown!.map((cd) => cd.remaining).listen(_pinBlockedFor.add);
    } else {
      _pinBlockedFor.add(Duration.zero);
    }
  }

  Stream<Duration> getPinBlockedFor() {
    return _pinBlockedFor;
  }
}
