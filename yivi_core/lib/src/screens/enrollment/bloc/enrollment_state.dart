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

class EnrollmentProvideEmail extends EnrollmentState {
  final String? email;

  EnrollmentProvideEmail({
    this.email,
  });
}

class EnrollmentEmailSent extends EnrollmentState {
  final String email;

  EnrollmentEmailSent({
    required this.email,
  });
}

class EnrollmentAcceptTerms extends EnrollmentState {
  final bool isAccepted;

  EnrollmentAcceptTerms({
    this.isAccepted = false,
  });
}

class Enrolling extends EnrollmentState {}

class EnrollmentSuccess extends EnrollmentState {}

class EnrollmentFailed extends EnrollmentState {
  final SessionError error;

  EnrollmentFailed({
    required this.error,
  });
}

class EnrollmentRetry extends EnrollmentState {}

class EnrollmentCompleted extends EnrollmentState {}
