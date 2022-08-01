part of 'enrollment_bloc.dart';

abstract class EnrollmentState {}

class EnrollmentIntroduction extends EnrollmentState {
  final int currentStepIndex;

  EnrollmentIntroduction({
    this.currentStepIndex = 0,
  });
}

class EnrollmentChoosePin extends EnrollmentState {}

class EnrollmentConfirmPin extends EnrollmentState {
  final bool confirmationFailed;

  EnrollmentConfirmPin({
    this.confirmationFailed = false,
  });
}

class EnrollmentProvideEmail extends EnrollmentState {}

class EnrollmentAcceptTerms extends EnrollmentState {
  final bool isAccepted;

  EnrollmentAcceptTerms({
    this.isAccepted = false,
  });
}

class EnrollmentSubmitted extends EnrollmentState {}

class EnrollmentSuccess extends EnrollmentState {}

class EnrollmentError extends EnrollmentState {}
