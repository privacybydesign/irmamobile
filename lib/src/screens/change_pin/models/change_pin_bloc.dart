import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/authentication_events.dart';
import 'package:irmamobile/src/models/change_pin_events.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_event.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_state.dart';

class ChangePinBloc extends Bloc<Object, ChangePinState> {
  ChangePinBloc() : super(ChangePinState());

  ChangePinBloc.test(ChangePinState initialState) : super(initialState);

  @override
  Stream<ChangePinState> mapEventToState(Object event) async* {
    if (event is ChangePinCanceled) {
      yield ChangePinState();
    } else if (event is OldPinEntered) {
      yield state.copyWith(
        validatingPin: true,
      );

      final authenticationEvent = await IrmaRepository.get().unlock(event.pin);
      if (authenticationEvent is AuthenticationSuccessEvent) {
        yield state.copyWith(
          validatingPin: false,
          oldPin: event.pin,
          oldPinVerified: ValidationState.valid,
        );
      } else if (authenticationEvent is AuthenticationFailedEvent) {
        yield state.copyWith(
          validatingPin: false,
          oldPinVerified: ValidationState.invalid,
          attemptsRemaining: authenticationEvent.remainingAttempts,
          blockedUntil: DateTime.now().add(Duration(seconds: authenticationEvent.blockedDuration)),
        );
      } else if (authenticationEvent is AuthenticationErrorEvent) {
        yield state.copyWith(
          validatingPin: false,
          oldPinVerified: ValidationState.error,
          error: authenticationEvent.error,
        );
      } else {
        throw Exception("Unexpected subtype of AuthenticationResult");
      }
    } else if (event is ToggleLongPin) {
      yield state.copyWith(
        longPin: !state.longPin,
        newPin: '',
        newPinConfirmed: ValidationState.initial,
      );
    } else if (event is NewPinChosen) {
      yield state.copyWith(
        newPin: event.pin,
        newPinConfirmed: ValidationState.initial,
      );
    } else if (event is NewPinConfirmed) {
      if (event.pin != state.newPin || (state.oldPin?.isEmpty ?? true) || (state.newPin?.isEmpty ?? true)) {
        yield state.copyWith(
          newPinConfirmed: ValidationState.invalid,
        );
      } else {
        yield state.copyWith(
          updatingPin: true,
        );

        final changePinEvent = await IrmaRepository.get().changePin(state.oldPin!, state.newPin!);
        if (changePinEvent is ChangePinSuccessEvent) {
          yield state.copyWith(
            updatingPin: false,
            newPinConfirmed: ValidationState.valid,
          );
        } else if (changePinEvent is ChangePinErrorEvent) {
          yield state.copyWith(
            updatingPin: false,
            newPinConfirmed: ValidationState.error,
            error: changePinEvent.error,
          );
        } else if (changePinEvent is ChangePinFailedEvent) {
          yield state.copyWith(
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
