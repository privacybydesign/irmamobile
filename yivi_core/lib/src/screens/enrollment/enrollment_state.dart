import "../../models/session.dart";

sealed class EnrollmentState {}

/// The welcome page: what Yivi is, and Get started.
class EnrollmentWelcome extends EnrollmentState {}

/// Step 1, "Before you start": the terms of use and the privacy policy to
/// read, and Accept and continue.
class EnrollmentTerms extends EnrollmentState {
  final EnrollmentStepNumber step;

  EnrollmentTerms({required this.step});
}

/// Step 2, "Help improve Yivi?": share error reports, or don't.
class EnrollmentErrorReports extends EnrollmentState {
  final EnrollmentStepNumber step;

  EnrollmentErrorReports({required this.step});
}

/// Where a step is in the numbered part of the enrollment (the terms, error
/// reports, the PIN twice, Face ID): "Step [number] of [total]".
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

  EnrollmentConfirmPin({this.step});
}

/// The page that offers Face ID, Touch ID or the fingerprint.
class EnrollmentBiometric extends EnrollmentState {
  final EnrollmentStepNumber step;

  EnrollmentBiometric({required this.step});
}

/// Waiting for the account, after the last step.
class Enrolling extends EnrollmentState {}

class EnrollmentFailed extends EnrollmentState {
  final SessionError error;

  EnrollmentFailed({required this.error});
}

class EnrollmentCompleted extends EnrollmentState {}
