import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/authentication_events.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_event.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_state.dart';
import 'package:quiver/async.dart';
import 'package:rxdart/subjects.dart';

class PinBloc extends Bloc<PinEvent, PinState> {
  StreamSubscription _lockedStreamSubscription;
  CountdownTimer _pinBlockedCountdown;
  final BehaviorSubject<Duration> _pinBlockedFor = BehaviorSubject<Duration>();

  PinBloc() : super(PinBloc._initialState) {
    _lockedStreamSubscription = IrmaRepository.get().getLocked().listen((isLocked) {
      if (isLocked) {
        add(Locked());
      }
    });
  }

  @override
  Future<void> close() async {
    _lockedStreamSubscription.cancel();
    super.close();
  }

  static PinState get _initialState => PinState(
        authenticated: false,
        authenticateInProgress: false,
        pinInvalid: false,
      );

  @override
  Stream<PinState> mapEventToState(PinEvent pinEvent) async* {
    if (pinEvent is Blocked) {
      setPinBlockedUntil(pinEvent.blockedUntil);
      yield PinState(
        pinInvalid: true,
        blockedUntil: pinEvent.blockedUntil,
        remainingAttempts: 0,
        authenticateInProgress: false,
      );
    } else if (pinEvent is Authenticate) {
      yield PinState(
        authenticateInProgress: true,
      );

      final authenticationEvent = await pinEvent.dispatch();
      if (authenticationEvent is AuthenticationSuccessEvent) {
        yield PinState(
          authenticated: true,
          authenticateInProgress: false,
        );
      } else if (authenticationEvent is AuthenticationFailedEvent) {
        // To have some timing slack we add some time to the blocked duration.
        if (authenticationEvent.blockedDuration > 0) {
          final blockedUntil = DateTime.now().add(Duration(seconds: authenticationEvent.blockedDuration + 5));
          setPinBlockedUntil(blockedUntil);
          yield PinState(
            pinInvalid: true,
            blockedUntil: blockedUntil,
            remainingAttempts: authenticationEvent.remainingAttempts,
            authenticateInProgress: false,
          );
        } else {
          yield PinState(
            pinInvalid: true,
            remainingAttempts: authenticationEvent.remainingAttempts,
            authenticateInProgress: false,
          );
        }
      } else if (authenticationEvent is AuthenticationErrorEvent) {
        yield PinState(
          error: authenticationEvent.error,
          authenticateInProgress: false,
        );
      } else {
        throw Exception("Unexpected subtype of AuthenticationResult");
      }
    } else if (pinEvent is Locked) {
      yield PinState(
        authenticated: false,
      );
    }
  }

  // Create derived stream that counts the seconds until pin can be used again.
  void setPinBlockedUntil(DateTime blockedUntil) {
    if (_pinBlockedCountdown != null) {
      _pinBlockedCountdown.cancel();
      _pinBlockedCountdown = null;
    }

    final delta = blockedUntil != null ? blockedUntil.difference(DateTime.now()) : Duration.zero;
    if (delta.inSeconds > 2) {
      _pinBlockedCountdown = CountdownTimer(delta, const Duration(seconds: 1));
      _pinBlockedCountdown.map((cd) => cd.remaining).listen(_pinBlockedFor.add);
    } else {
      _pinBlockedFor.add(Duration.zero);
    }
  }

  Stream<Duration> getPinBlockedFor() {
    return _pinBlockedFor;
  }
}
