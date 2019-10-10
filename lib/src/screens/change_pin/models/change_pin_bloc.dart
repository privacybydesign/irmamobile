import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_event.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_state.dart';

class ChangePinBloc extends Bloc<ChangePinEvent, ChangePinState> {
  final ChangePinState startingState;

  ChangePinBloc() : startingState = null;

  ChangePinBloc.test(this.startingState);

  @override
  ChangePinState get initialState {
    if (startingState == null) {
      return ChangePinState();
    } else {
      return startingState.copyWith();
    }
  }

  @override
  Stream<ChangePinState> mapEventToState(ChangePinEvent event) async* {
    if (event is ChangePinCanceled) {
      yield ChangePinState();
    }

    if (event is OldPinEntered) {
      // TODO: check pin in correct (event.pin)
      yield currentState.copyWith(
        oldPinVerified: ValidationState.valid,
      );
    }

    if (event is NewPinChosen) {
      yield currentState.copyWith(
        newPin: event.pin,
        newPinConfirmed: ValidationState.initial,
      );
    }

    if (event is NewPinConfirmed) {
      final bool pinConfirmed = event.pin == currentState.newPin;
      // TODO: update the pin
      yield currentState.copyWith(
        newPinConfirmed: pinConfirmed ? ValidationState.valid : ValidationState.invalid,
      );
    }
  }
}
