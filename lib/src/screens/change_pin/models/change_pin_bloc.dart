import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/authentication_events.dart';
import 'package:irmamobile/src/models/change_pin_events.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_event.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_state.dart';

class ChangePinBloc extends Bloc<Object, ChangePinState> {
  @override
  final ChangePinState initialState;

  ChangePinBloc() : initialState = ChangePinState();

  ChangePinBloc.test(this.initialState);

  @override
  Stream<ChangePinState> mapEventToState(Object event) async* {
    if (event is ChangePinCanceled) {
      yield ChangePinState();
    } else if (event is OldPinEntered) {
      yield currentState.copyWith(
        validatingPin: true,
      );

      final authenticationEvent = await IrmaRepository.get().unlock(event.pin);
      if (authenticationEvent is AuthenticationSuccessEvent) {
        yield currentState.copyWith(
          validatingPin: false,
          oldPin: event.pin,
          oldPinVerified: ValidationState.valid,
        );
      } else if (authenticationEvent is AuthenticationFailedEvent) {
        yield currentState.copyWith(
          validatingPin: false,
          oldPinVerified: ValidationState.invalid,
          attemptsRemaining: authenticationEvent.remainingAttempts,
          blockedUntil: DateTime.now().add(Duration(seconds: authenticationEvent.blockedDuration)),
        );
      } else if (authenticationEvent is AuthenticationErrorEvent) {
        yield currentState.copyWith(
          validatingPin: false,
          oldPinVerified: ValidationState.error,
          error: authenticationEvent.error,
        );
      } else {
        throw Exception("Unexpected subtype of AuthenticationResult");
      }
    } else if (event is ToggleLongPin) {
      yield currentState.copyWith(
        longPin: !currentState.longPin,
        newPin: '',
        newPinConfirmed: ValidationState.initial,
      );
    } else if (event is NewPinChosen) {
      yield currentState.copyWith(
        newPin: event.pin,
        newPinConfirmed: ValidationState.initial,
      );
    } else if (event is NewPinConfirmed) {
      final bool pinConfirmed = event.pin == currentState.newPin;

      if (event.pin != currentState.newPin) {
        yield currentState.copyWith(
          newPinConfirmed: ValidationState.invalid,
        );
      } else {
        yield currentState.copyWith(
          updatingPin: true,
        );

        final changePinEvent = await IrmaRepository.get().changePin(currentState.oldPin, currentState.newPin);
        if (changePinEvent is ChangePinSuccessEvent) {
          yield currentState.copyWith(
            updatingPin: false,
            newPinConfirmed: ValidationState.valid,
          );
        } else if (changePinEvent is ChangePinErrorEvent) {
          yield currentState.copyWith(
            updatingPin: false,
            newPinConfirmed: ValidationState.error,
            error: changePinEvent.error,
          );
        } else if (changePinEvent is ChangePinFailedEvent) {
          yield currentState.copyWith(
            updatingPin: false,
            newPinConfirmed: ValidationState.error,
            errorMessage: "Unexpected old pin rejection by server", //TODO: improve error handling
          );
        } else {
          throw Exception("Unexpected subtype of changePinResult");
        }
      }
    }
  }
}
