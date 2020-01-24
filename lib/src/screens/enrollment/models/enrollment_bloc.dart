import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:email_validator/email_validator.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_event.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_state.dart';

class EnrollmentBloc extends Bloc<Object, EnrollmentState> {
  @override
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
        pinConfirmed: false,
        pinMismatch: false,
        showPinValidation: false,
        emailValid: false,
        emailSkipped: false,
        showEmailValidation: false,
      );
    } else if (event is ConfirmationPinSubmitted) {
      final bool pinConfirmed = event.pin == currentState.pin;
      yield currentState.copyWith(
        pinConfirmed: pinConfirmed,
        pinMismatch: !pinConfirmed,
        showPinValidation: true,
        showEmailValidation: false,
        emailValid: false,
        emailSkipped: false,
        retry: currentState.retry + 1,
      );
    } else if (event is EmailSubmitted) {
      final isEmailValid = EmailValidator.validate(event.email);
      yield currentState.copyWith(
        email: event.email,
        emailValid: isEmailValid,
        showEmailValidation: true,
      );

      if (isEmailValid) {
        dispatch(Enroll());
      }
    } else if (event is EmailSkipped) {
      yield currentState.copyWith(
        emailSkipped: true,
      );

      dispatch(Enroll());
    } else if (event is Enroll) {
      yield currentState.copyWith(
        isSubmitting: true,
        enrollementFailed: false,
      );
      // TODO: get a future back and change the state based on it, which can
      // be used by animation/outro?
      IrmaRepository.get().enroll(
        email: currentState.email.trim(),
        pin: currentState.pin,
        language: 'nl',
      );

      // Once the enroll function on the repository is a future which could return an error
      // The state below can be yielded to display the error state.
      // yield currentState.copyWith(
      //   isSubmitting: false,
      //   enrollementFailed: true,
      // );
    }
  }
}
