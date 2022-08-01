import 'package:bloc/bloc.dart';

import '../../../data/irma_repository.dart';
import '../../../models/enrollment_events.dart';
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

  @override
  Stream<EnrollmentState> mapEventToState(EnrollmentBlocEvent event) async* {
    final state = this.state; // To prevent the need for type casting.

    // Introduction
    if (state is EnrollmentIntroduction) {
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
      if (event is EnrollmentChosePin) {
        _pin = event.pin;
        yield EnrollmentConfirmPin();
      } else if (event is EnrollmentPreviousPressed) {
        yield EnrollmentIntroduction(
          currentStepIndex: IntroductionScreen.introductionSteps.length - 1,
        );
      }
    }
    //Confirm Pin
    else if (state is EnrollmentConfirmPin) {
      if (event is EnrollmentConfirmedPin) {
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
        if (event is EnrollmentEmailProvided) {
          _email = event.email;
        }
        yield EnrollmentSubmitted();
        final enrollment = await repo.enroll(
          email: _email?.trim() ?? '',
          pin: _pin!,
          language: language,
        );
        if (enrollment is EnrollmentFailureEvent) {
          yield EnrollmentError();
        }
        yield EnrollmentSuccess();
      } else if (event is EnrollmentPreviousPressed) {
        yield EnrollmentAcceptTerms(
          isAccepted: true,
        );
      }
    }
  }
}
