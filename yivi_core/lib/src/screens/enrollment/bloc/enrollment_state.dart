part of "enrollment_bloc.dart";

abstract class EnrollmentState {}

/// The welcome page: what Yivi is, the error-report switch and the terms.
class EnrollmentWelcome extends EnrollmentState {
  final bool isAccepted;

  EnrollmentWelcome({this.isAccepted = false});
}

/// Where a step is in the numbered part of the enrollment (the PIN, Face ID,
/// the e-mail address): "Step [number] of [total]".
class EnrollmentStepNumber {
  final int number;
  final int total;

  const EnrollmentStepNumber(this.number, this.total);
}

class EnrollmentChoosePin extends EnrollmentState {
  final EnrollmentStepNumber? step;

  EnrollmentChoosePin({this.step});
}

class EnrollmentConfirmPin extends EnrollmentState {
  final EnrollmentStepNumber? step;
  final bool confirmationFailed;

  EnrollmentConfirmPin({this.step, this.confirmationFailed = false});
}

/// The page that offers Face ID, Touch ID or the fingerprint.
class EnrollmentBiometric extends EnrollmentState {
  final EnrollmentStepNumber step;

  EnrollmentBiometric({required this.step});
}

/// The optional step that links an e-mail address to the app.
class EnrollmentEmail extends EnrollmentState {
  final EnrollmentStepNumber step;

  EnrollmentEmail({required this.step});
}

/// Waiting for the account, after the last step.
class Enrolling extends EnrollmentState {}

class EnrollmentFailed extends EnrollmentState {
  final SessionError error;

  EnrollmentFailed({required this.error});
}

class EnrollmentCompleted extends EnrollmentState {}
