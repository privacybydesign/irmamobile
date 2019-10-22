import 'package:equatable/equatable.dart';
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
  final bool showEmailValidation;
  final bool showPinValidation;

  EnrollmentState({
    this.pin,
    this.email = "",
    this.pinConfirmed = false,
    this.emailValid = false,
    this.showEmailValidation = false,
    this.showPinValidation = false,
  });

  EnrollmentState copyWith({
    String pin,
    String email,
    bool pinConfirmed,
    bool emailValid,
    bool showEmailValidation,
    bool showPinValidation,
  }) {
    return new EnrollmentState(
      pin: pin ?? this.pin,
      email: email ?? this.email,
      pinConfirmed: pinConfirmed ?? this.pinConfirmed,
      emailValid: emailValid ?? this.emailValid,
      showEmailValidation: showEmailValidation ?? this.showEmailValidation,
      showPinValidation: showPinValidation ?? this.showPinValidation,
    );
  }

  @override
  String toString() {
    return 'EnrollmentState {pin: ${pin == null ? null : '*' * pin.length}, email: $email, pinConfirmed: $pinConfirmed, emailValid: $emailValid, showEmailValidation: $showEmailValidation, showPinValidation: $showPinValidation}';
  }

  @override
  List<Object> get props {
    return [pin, email, pinConfirmed, emailValid];
  }
}
