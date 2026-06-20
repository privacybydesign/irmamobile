import "package:flutter_bloc/flutter_bloc.dart";

import "../../../data/irma_repository.dart";
import "../../../models/enrollment_events.dart";
import "../../../models/session.dart";
import "../../../util/bloc_event_transformer.dart";
import "../introduction/introduction_screen.dart";

part "enrollment_event.dart";
part "enrollment_state.dart";

class EnrollmentBloc extends Bloc<EnrollmentBlocEvent, EnrollmentState> {
  final String language;
  final IrmaRepository repo;

  String? _email;
  String? _pin;

  EnrollmentBloc({required this.language, required this.repo})
    : super(EnrollmentIntroduction()) {
    on<EnrollmentBlocEvent>((event, emit) async {
      final state = this.state; // To prevent the need for type casting.

      // Retry enrollment
      if (event is EnrollmentRetried) {
        emit(Enrolling());
        emit(await _enroll());
      }
      // Introduction
      else if (state is EnrollmentIntroduction) {
        if (event is EnrollmentNextPressed) {
          if (state.currentStepIndex <
              IntroductionScreen.introductionSteps.length - 1) {
            emit(
              EnrollmentIntroduction(
                currentStepIndex: state.currentStepIndex + 1,
              ),
            );
          } else {
            emit(EnrollmentAcceptTerms());
          }
        } else if (event is EnrollmentPreviousPressed) {
          emit(
            EnrollmentIntroduction(
              currentStepIndex: state.currentStepIndex > 0
                  ? state.currentStepIndex - 1
                  : 0,
            ),
          );
        }
      }
      // Accept terms
      else if (state is EnrollmentAcceptTerms) {
        if (event is EnrollmentNextPressed) {
          if (!state.isAccepted) {
            throw ("Continuing without accepting the terms is not possible");
          }
          emit(EnrollmentChoosePin());
        } else if (event is EnrollmentPreviousPressed) {
          emit(
            EnrollmentIntroduction(
              currentStepIndex: IntroductionScreen.introductionSteps.length - 1,
            ),
          );
        }
        // Terms are toggled
        else if (event is EnrollmentTermsUpdated) {
          emit(EnrollmentAcceptTerms(isAccepted: event.isAccepted));
        }
      }
      // Choose Pin
      else if (state is EnrollmentChoosePin) {
        if (event is EnrollmentPinChosen) {
          _pin = event.pin;
          emit(EnrollmentConfirmPin());
        } else if (event is EnrollmentPreviousPressed) {
          emit(EnrollmentAcceptTerms(isAccepted: true));
        }
      }
      // Confirm Pin
      else if (state is EnrollmentConfirmPin) {
        if (event is EnrollmentPinMismatch) {
          emit(EnrollmentChoosePin());
        }
        if (event is EnrollmentPinConfirmed) {
          if (_pin == event.pin) {
            emit(EnrollmentProvideEmail());
          } else {
            emit(EnrollmentConfirmPin(confirmationFailed: true));
          }
        } else if (event is EnrollmentPreviousPressed) {
          emit(EnrollmentChoosePin());
        }
      }
      // Provide email
      else if (state is EnrollmentProvideEmail) {
        if (event is EnrollmentEmailProvided ||
            event is EnrollmentEmailSkipped) {
          _email = event is EnrollmentEmailProvided ? event.email : null;
          emit(Enrolling());
          emit(await _enroll());
        }
        if (event is EnrollmentPreviousPressed) {
          emit(EnrollmentChoosePin());
        }
      } else if (state is EnrollmentEmailSent) {
        if (event is EnrollmentNextPressed) {
          emit(EnrollmentCompleted());
        }
      } else if (state is EnrollmentFailed &&
          event is EnrollmentPreviousPressed) {
        emit(EnrollmentProvideEmail(email: _email));
      }
    }, transformer: sequentialTransformer());
  }

  Future<EnrollmentState> _enroll() async {
    var enrollment = await repo.enroll(
      email: _email?.trim() ?? "",
      pin: _pin!,
      language: language,
    );
    if (enrollment is EnrollmentFailureEvent) {
      return EnrollmentFailed(error: enrollment.error);
    } else if (_email != null) {
      return EnrollmentEmailSent(email: _email!);
    }
    return EnrollmentCompleted();
  }
}
