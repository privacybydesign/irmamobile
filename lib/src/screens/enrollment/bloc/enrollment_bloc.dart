import 'package:bloc/bloc.dart';

import '../../../data/irma_repository.dart';
import '../../../models/enrollment_events.dart';
import '../../../models/session.dart';
import '../introduction/introduction_screen.dart';

part 'enrollment_event.dart';
part 'enrollment_state.dart';

class EnrollmentBloc extends Bloc<EnrollmentBlocEvent, EnrollmentState> {
  final String language;
  final IrmaRepository repo;

  String? _email;
  String? _pin;

  EnrollmentBloc({
    required this.language,
    required this.repo,
  }) : super(EnrollmentIntroduction());

  Future<EnrollmentState> _enroll() async {
    var enrollment = await repo.enroll(
      email: _email?.trim() ?? '',
      pin: _pin!,
      language: language,
    );
    if (enrollment is EnrollmentFailureEvent) {
      return EnrollmentFailed(
        error: enrollment.error,
      );
    } else if (_email != null) {
      return EnrollmentEmailSent(
        email: _email!,
      );
    }
    return EnrollmentCompleted();
  }

  @override
  Stream<EnrollmentState> mapEventToState(EnrollmentBlocEvent event) async* {
    final state = this.state; // To prevent the need for type casting.

    // Retry enrollment
    if (event is EnrollmentRetried) {
      yield Enrolling();
      yield await _enroll();
    }
    // Introduction
    else if (state is EnrollmentIntroduction) {
      if (event is EnrollmentNextPressed) {
        if (state.currentStepIndex < IntroductionScreen.introductionSteps.length - 1) {
          yield EnrollmentIntroduction(currentStepIndex: state.currentStepIndex + 1);
        } else {
          yield EnrollmentChoosePin();
        }
      } else if (event is EnrollmentPreviousPressed) {
        yield EnrollmentIntroduction(
          currentStepIndex: state.currentStepIndex > 0 ? state.currentStepIndex - 1 : 0,
        );
      }
    }
    // Choose Pin
    else if (state is EnrollmentChoosePin) {
      if (event is EnrollmentPinChosen) {
        _pin = event.pin;
        yield EnrollmentConfirmPin();
      } else if (event is EnrollmentPreviousPressed) {
        yield EnrollmentIntroduction(
          currentStepIndex: IntroductionScreen.introductionSteps.length - 1,
        );
      }
    }
    // Confirm Pin
    else if (state is EnrollmentConfirmPin) {
      if (event is EnrollmentPinMismatch) {
        yield EnrollmentChoosePin();
      }
      if (event is EnrollmentPinConfirmed) {
        if (_pin == event.pin) {
          yield EnrollmentAcceptTerms();
        } else {
          yield EnrollmentConfirmPin(
            confirmationFailed: true,
          );
        }
      } else if (event is EnrollmentPreviousPressed) {
        yield EnrollmentChoosePin();
      }
    }
    // Accept terms
    else if (state is EnrollmentAcceptTerms) {
      if (event is EnrollmentNextPressed) {
        if (!state.isAccepted) {
          throw ('Continuing without accepting the terms is not possible');
        }
        yield EnrollmentProvideEmail();
      } else if (event is EnrollmentPreviousPressed) {
        yield EnrollmentConfirmPin();
      }
      // Terms are toggled
      else if (event is EnrollmentTermsUpdated) {
        yield EnrollmentAcceptTerms(
          isAccepted: event.isAccepted,
        );
      }
    }
    // Provide email
    else if (state is EnrollmentProvideEmail) {
      if (event is EnrollmentEmailProvided || event is EnrollmentEmailSkipped) {
        _email = event is EnrollmentEmailProvided ? event.email : null;
        yield Enrolling();
        yield await _enroll();
      }
      if (event is EnrollmentPreviousPressed) {
        yield EnrollmentAcceptTerms(
          isAccepted: true,
        );
      }
    } else if (state is EnrollmentEmailSent) {
      if (event is EnrollmentNextPressed) {
        yield EnrollmentCompleted();
      }
    } else if (state is EnrollmentFailed && event is EnrollmentPreviousPressed) {
      yield EnrollmentProvideEmail(
        email: _email,
      );
    }
  }
}
