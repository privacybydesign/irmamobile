import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class EnrollmentState with EquatableMixinBase, EquatableMixin {
  final String pin;
  final String email;

  // This value is null initially.
  // When the pin is confirmed this value will be true.
  // When the confirm pin did not match this value will be false
  final bool pinConfirmed;

  // This value is null initially.
  // When a valid email address is entered this value is true.
  // When a invalid email address is entered this value will be false
  final bool emailValidated;

  EnrollmentState({
    this.pin,
    this.email,
    this.pinConfirmed,
    this.emailValidated,
  });

  EnrollmentState copyWith({
    String pin,
    String email,
    bool pinConfirmed,
    bool emailValidated,
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
    final String code = '*' * pin.length;

    return 'EnrollmentState {pin: $code, email: $email}';
  }

  @override
  List<Object> get props {
    return [pin, email, pinConfirmed, emailValidated];
  }
}
