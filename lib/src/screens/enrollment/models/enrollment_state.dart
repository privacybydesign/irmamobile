import 'package:equatable/equatable.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:meta/meta.dart';

enum ValidationState { initial, valid, invalid }

@immutable
class EnrollmentState with EquatableMixin {
  // Pin and email values as submitted
  final String pin;
  final String email;

  // Booleans that indicate:
  //  - Whether the submitted confirmation pin matches the initially given pin (initially false)
  //  - Whether the email address that is submitted is valid (initially false)
  //  - Whether to show the validation status of the email address or pin (initially false)
  final bool pinConfirmed;
  final bool emailValid;
  final bool emailSkipped;
  final bool showEmailValidation;
  final bool showPinValidation;
  final bool pinMismatch;
  final bool isSubmitting;
  final bool submittingFailed;
  final SessionError error;
  final int retry;

  EnrollmentState({
    this.pin,
    this.email = "",
    this.pinConfirmed = false,
    this.pinMismatch = false,
    this.emailValid = false,
    this.emailSkipped = false,
    this.showEmailValidation = false,
    this.showPinValidation = false,
    this.isSubmitting = false,
    this.submittingFailed = false,
    this.error,
    this.retry = 0,
  });

  EnrollmentState copyWith({
    String pin,
    String email,
    bool pinConfirmed,
    bool pinMismatch,
    bool emailValid,
    bool emailSkipped,
    bool showEmailValidation,
    bool showPinValidation,
    bool isSubmitting,
    bool submittingFailed,
    SessionError error,
    int retry,
  }) {
    return EnrollmentState(
      pin: pin ?? this.pin,
      email: email ?? this.email,
      pinConfirmed: pinConfirmed ?? this.pinConfirmed,
      pinMismatch: pinMismatch ?? this.pinMismatch,
      emailValid: emailValid ?? this.emailValid,
      emailSkipped: emailSkipped ?? this.emailSkipped,
      showEmailValidation: showEmailValidation ?? this.showEmailValidation,
      showPinValidation: showPinValidation ?? this.showPinValidation,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submittingFailed: submittingFailed ?? this.submittingFailed,
      error: error ?? this.error,
      retry: retry ?? this.retry,
    );
  }

  @override
  String toString() {
    return '''EnrollmentState
     {
        pin: ${pin == null ? null : '*' * pin.length}, 
        email: $email, 
        pinConfirmed: $pinConfirmed, 
        pinMismatch: $pinMismatch,
        emailValid: $emailValid, 
        emailSkipped: $emailSkipped, 
        showEmailValidation: $showEmailValidation, 
        showPinValidation: $showPinValidation, 
        retry: $retry, 
        isSubmitting: $isSubmitting, 
        submittingFailed: $submittingFailed,
    }''';
  }

  @override
  List<Object> get props {
    return [
      pin,
      email,
      pinConfirmed,
      pinMismatch,
      emailValid,
      emailSkipped,
      showEmailValidation,
      showPinValidation,
      retry,
      isSubmitting,
      submittingFailed,
      error,
    ];
  }
}
