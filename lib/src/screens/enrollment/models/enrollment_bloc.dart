import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:email_validator/email_validator.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_event.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_state.dart';

class EnrollmentBloc extends Bloc<EnrollmentEvent, EnrollmentState> {
  final EnrollmentState startingState;

  EnrollmentBloc() : startingState = null;

  EnrollmentBloc.test(this.startingState);

  @override
  EnrollmentState get initialState {
    if (startingState == null) {
      return EnrollmentState();
    } else {
      return startingState.copyWith();
    }
  }

  @override
  Stream<EnrollmentState> mapEventToState(EnrollmentEvent event) async* {
    if (event is EnrollmentCanceled) {
      yield EnrollmentState();
    }

    if (event is PinChosen) {
      yield currentState.copyWith(
        pin: event.pin,
      );
    }

    if (event is PinConfirmed) {
      final bool pinConfirmed = event.pin == currentState.pin;
      yield currentState.copyWith(
        pinConfirmed: pinConfirmed,
      );
    }

    if (event is EmailChanged) {
      yield currentState.copyWith(
        email: event.email,
      );
    }

    if (event is EmailSubmitted) {
      bool emailValidated;

      if (currentState.email == null || currentState.email == '') {
        emailValidated = true;
      } else {
        emailValidated = EmailValidator.validate(currentState.email) == true;
      }

      yield currentState.copyWith(
        emailValidated: emailValidated,
      );

      if (emailValidated == true) {
        // TODO submit enrollment pin/email to backend
        yield EnrollmentState();
      }
    }
  }
}
