import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

enum ValidationState { initial, valid, invalid }

@immutable
class EnrollmentState with EquatableMixinBase, EquatableMixin {
  final String pin;
  final String email;

  // This value is "initial" initially
  // When the pin is confirmed this value will be "valid"
  // When the confirm pin did not match this value will be "invalid"
  final ValidationState pinConfirmed;

  // This value is "initial" initially
  // When a valid email address is entered this value is "valid"
  // When a invalid email address is entered this value will be "invalid"
  final ValidationState emailValidated;

  EnrollmentState({
    this.pin,
    this.email,
    this.pinConfirmed = ValidationState.initial,
    this.emailValidated = ValidationState.initial,
  });

  EnrollmentState copyWith({
    String pin,
    String email,
    ValidationState pinConfirmed,
    ValidationState emailValidated,
  }) {
    return new EnrollmentState(
      pin: pin ?? this.pin,
      email: email ?? this.email,
      pinConfirmed: pinConfirmed ?? this.pinConfirmed,
      emailValidated: emailValidated ?? this.emailValidated,
    );
  }

  @override
  String toString() {
    return 'EnrollmentState {pin: $pin, email: $email, pin confirmed: $pinConfirmed, email validated: $emailValidated}';
  }

  @override
  List<Object> get props {
    return [pin, email, pinConfirmed, emailValidated];
  }
}
