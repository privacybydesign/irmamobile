import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_event.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_state.dart';

class ChangePinBloc extends Bloc<Object, ChangePinState> {
  final ChangePinState initialState;

  ChangePinBloc() : initialState = ChangePinState();

  ChangePinBloc.test(this.initialState);

  @override
  Stream<ChangePinState> mapEventToState(Object event) async* {
    if (event is ChangePinCanceled) {
      yield ChangePinState();
    } else if (event is OldPinEntered) {
      // TODO: check pin in correct (event.pin)
      yield currentState.copyWith(
        oldPinVerified: ValidationState.valid,
      );
    } else if (event is NewPinChosen) {
      yield currentState.copyWith(
        newPin: event.pin,
        newPinConfirmed: ValidationState.initial,
      );
    } else if (event is NewPinConfirmed) {
      final bool pinConfirmed = event.pin == currentState.newPin;
      // TODO: update the pin
      yield currentState.copyWith(
        newPinConfirmed: pinConfirmed ? ValidationState.valid : ValidationState.invalid,
      );
    }
  }
}
