import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/screens/change_pin/models/validation_state.dart';
import 'package:meta/meta.dart';

import 'old_pin_verification_state.dart';

@immutable
class ChangePinState {
  final String newPin;
  final String oldPin;

  final int attemptsRemaining;
  final DateTime? blockedUntil;
  final SessionError? error;

  final ValidationState newPinConfirmed;

  const ChangePinState({
    this.oldPin = '',
    this.newPin = '',
    this.newPinConfirmed = ValidationState.initial,
    this.attemptsRemaining = 0,
    this.blockedUntil,
    this.error,
  });

  ChangePinState copyWith({
    String? oldPin,
    String? newPin,
    ValidationState newPinConfirmed = ValidationState.initial,
    int? attemptsRemaining,
    DateTime? blockedUntil,
    SessionError? error,
    String? errorMessage,
  }) {
    return ChangePinState(
      oldPin: oldPin ?? this.oldPin,
      newPin: newPin ?? this.newPin,
      newPinConfirmed: newPinConfirmed,
      attemptsRemaining: attemptsRemaining ?? this.attemptsRemaining,
      blockedUntil: blockedUntil ?? this.blockedUntil,
      error: error ?? this.error,
    );
  }
}
