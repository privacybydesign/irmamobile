part of 'enrollment_bloc.dart';

abstract class EnrollmentBlocEvent {}

class EnrollmentChosePin implements EnrollmentBlocEvent {
  final String pin;

  EnrollmentChosePin(this.pin);
}

class EnrollmentConfirmedPin implements EnrollmentBlocEvent {
  final String pin;

  EnrollmentConfirmedPin(
    this.pin,
  );
}

class EnrollmentTermsUpdated implements EnrollmentBlocEvent {
  final bool isAccepted;

  EnrollmentTermsUpdated({
    required this.isAccepted,
  });
}

class EnrollmentEmailProvided implements EnrollmentBlocEvent {
  final String email;

  EnrollmentEmailProvided(
    this.email,
  );
}

class EnrollmentEmailSkipped implements EnrollmentBlocEvent {}

class EnrollmentNextPressed implements EnrollmentBlocEvent {}

class EnrollmentPreviousPressed implements EnrollmentBlocEvent {}

class EnrollmentRetried implements EnrollmentBlocEvent {}
