part of 'enrollment_bloc.dart';

abstract class EnrollmentBlocEvent {}

class EnrollmentPinChosen implements EnrollmentBlocEvent {
  final String pin;

  EnrollmentPinChosen(this.pin);
}

class EnrollmentPinConfirmed implements EnrollmentBlocEvent {
  final String pin;

  EnrollmentPinConfirmed(
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
