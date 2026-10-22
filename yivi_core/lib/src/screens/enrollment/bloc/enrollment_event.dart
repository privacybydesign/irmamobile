part of "enrollment_bloc.dart";

abstract class EnrollmentBlocEvent {}

class EnrollmentPinChosen implements EnrollmentBlocEvent {
  final String pin;

  EnrollmentPinChosen(this.pin);
}

class EnrollmentPinConfirmed implements EnrollmentBlocEvent {
  final String pin;

  EnrollmentPinConfirmed(this.pin);
}

class EnrollmentTermsUpdated implements EnrollmentBlocEvent {
  final bool isAccepted;

  EnrollmentTermsUpdated({required this.isAccepted});
}

/// Face ID was turned on or declined: the page is done either way.
class EnrollmentBiometricDone implements EnrollmentBlocEvent {}

/// The e-mail step was skipped, or the address is linked.
class EnrollmentEmailDone implements EnrollmentBlocEvent {}

/// The e-mail step needs the account, and it could not be made.
class EnrollmentAccountFailed implements EnrollmentBlocEvent {
  final SessionError error;

  EnrollmentAccountFailed(this.error);
}

class EnrollmentNextPressed implements EnrollmentBlocEvent {}

class EnrollmentPreviousPressed implements EnrollmentBlocEvent {}

class EnrollmentRetried implements EnrollmentBlocEvent {}

class EnrollmentPinMismatch implements EnrollmentBlocEvent {}
