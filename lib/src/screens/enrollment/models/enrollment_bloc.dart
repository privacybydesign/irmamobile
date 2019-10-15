import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:email_validator/email_validator.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_event.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_state.dart';

class EnrollmentBloc extends Bloc<Object, EnrollmentState> {
  final EnrollmentState initialState;

  EnrollmentBloc() : initialState = EnrollmentState();

  EnrollmentBloc.test(this.initialState);

  @override
  Stream<EnrollmentState> mapEventToState(Object event) async* {
    if (event is EnrollmentCanceled) {
      yield EnrollmentState();
    } else if (event is PinSubmitted) {
      yield currentState.copyWith(
        pin: event.pin,
      );
    } else if (event is ConfirmationPinSubmitted) {
      final bool pinConfirmed = event.pin == currentState.pin;
      yield currentState.copyWith(
        pinConfirmed: pinConfirmed,
        showPinValidation: true,
      );
    } else if (event is EmailChanged) {
      yield currentState.copyWith(
        email: event.email,
        emailValid: EmailValidator.validate(event.email),
      );
    } else if (event is EmailSubmitted) {
      yield currentState.copyWith(
        showEmailValidation: true,
      );
    }
  }
}
