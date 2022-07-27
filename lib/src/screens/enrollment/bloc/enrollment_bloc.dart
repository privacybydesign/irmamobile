import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:email_validator/email_validator.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/enrollment_events.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/screens/enrollment/bloc/enrollment_event.dart';
import 'package:irmamobile/src/screens/enrollment/bloc/enrollment_state.dart';

class EnrollmentBloc extends Bloc<Object, EnrollmentState> {
  EnrollmentBloc(String languageCode) : super(EnrollmentState(languageCode: languageCode));

  EnrollmentBloc.test(EnrollmentState initialState) : super(initialState);

  @override
  Stream<EnrollmentState> mapEventToState(Object event) async* {
    if (event is EnrollmentCanceled) {
      yield EnrollmentState();
    } else if (event is PinSubmitted) {
      yield state.copyWith(
        pin: event.pin,
        pinConfirmed: false,
        pinMismatch: false,
        showPinValidation: false,
        emailValid: false,
        emailSkipped: false,
        showEmailValidation: false,
      );
    } else if (event is ConfirmationPinSubmitted) {
      final bool pinConfirmed = event.pin == state.pin;
      yield state.copyWith(
        pinConfirmed: pinConfirmed,
        pinMismatch: !pinConfirmed,
        showPinValidation: true,
        showEmailValidation: false,
        emailValid: false,
        emailSkipped: false,
        retry: state.retry + 1,
      );
    } else if (event is EmailSubmitted) {
      final isEmailValid = EmailValidator.validate(event.email);
      yield state.copyWith(
        email: event.email,
        emailValid: isEmailValid,
        showEmailValidation: true,
      );

      if (isEmailValid) {
        add(Enroll());
      }
    } else if (event is EmailSkipped) {
      yield state.copyWith(
        emailSkipped: true,
      );

      add(Enroll());
    } else if (event is Enroll) {
      yield state.copyWith(
        isSubmitting: true,
        submittingFailed: false, // reset incase of retrying
      );

      if (state.pin.isEmpty) {
        yield state.copyWith(
            error: SessionError(errorType: 'emptyPin', info: 'No pin code was specified for enrollment'));
        return;
      }

      final status = await IrmaRepository.get().enroll(
        email: state.email.trim(),
        pin: state.pin,
        language: state.languageCode,
      );

      if (status is EnrollmentFailureEvent) {
        yield state.copyWith(
          isSubmitting: false,
          submittingFailed: true,
          error: status.error,
        );
      } else if (status is EnrollmentSuccessEvent) {
        yield state.copyWith(
          isSubmitting: false,
        );
      }
    }
  }
}
