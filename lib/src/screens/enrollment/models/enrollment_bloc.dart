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
        showPinValidation: false,
        emailValid: false,
        showEmailValidation: false,
      );
    } else if (event is ConfirmationPinSubmitted) {
      final bool pinConfirmed = event.pin == currentState.pin;
      yield currentState.copyWith(
        pinConfirmed: pinConfirmed,
        showPinValidation: true,
        showEmailValidation: false,
        emailValid: false,
        retry: currentState.retry + 1,
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

      if (currentState.pinConfirmed && (currentState.email.trim() == "" || currentState.emailValid)) {
        // TODO: get a future back and change the state based on it, which can
        // be used by animation/outro?
        IrmaRepository.get().enroll(
          email: currentState.email.trim(),
          pin: currentState.pin,
          language: 'nl',
        );
      }
    }
  }
}
