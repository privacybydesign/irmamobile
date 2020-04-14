import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/authentication_events.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_event.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_state.dart';

class PinBloc extends Bloc<PinEvent, PinState> {
  StreamSubscription _lockedStreamSubscription;

  PinBloc() {
    _lockedStreamSubscription = IrmaRepository.get().getLocked().listen((isLocked) {
      if (isLocked) {
        dispatch(Locked());
      }
    });
  }

  @override
  void dispose() {
    _lockedStreamSubscription.cancel();
    super.dispose();
  }

  @override
  PinState get initialState => PinState(
        authenticated: false,
        authenticateInProgress: false,
        pinInvalid: false,
      );

  @override
  Stream<PinState> mapEventToState(PinEvent pinEvent) async* {
    if (pinEvent is Authenticate) {
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
        yield PinState(
          pinInvalid: true,
          blockedUntil: DateTime.now().add(Duration(seconds: authenticationEvent.blockedDuration)),
          remainingAttempts: authenticationEvent.remainingAttempts,
          authenticateInProgress: false,
        );
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
}
