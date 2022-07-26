import 'package:equatable/equatable.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:meta/meta.dart';

import '../../pin/yivi_pin_screen.dart';

enum ValidationState { initial, valid, invalid, error }

@immutable
class ChangePinState with EquatableMixin {
  final String newPin;
  final String oldPin;
  final bool validatingPin;
  final bool updatingPin;
  final bool longPin;

  final int attemptsRemaining;
  final DateTime? blockedUntil;
  final SessionError? error;
  final String? errorMessage;

  final ValidationState oldPinVerified;
  final ValidationState newPinConfirmed;

  ChangePinState({
    this.oldPin = '',
    this.newPin = '',
    this.validatingPin = false,
    this.updatingPin = false,
    this.oldPinVerified = ValidationState.initial,
    this.newPinConfirmed = ValidationState.initial,
    this.attemptsRemaining = 0,
    this.blockedUntil,
    this.error,
    this.errorMessage,
  }) : longPin = newPin.length > shortPinSize;

  ChangePinState copyWith({
    String? oldPin,
    String? newPin,
    bool? validatingPin,
    bool? updatingPin,
    ValidationState oldPinVerified = ValidationState.initial,
    ValidationState newPinConfirmed = ValidationState.initial,
    int? attemptsRemaining,
    DateTime? blockedUntil,
    SessionError? error,
    String? errorMessage,
  }) {
    return ChangePinState(
        oldPin: oldPin ?? this.oldPin,
        newPin: newPin ?? this.newPin,
        validatingPin: validatingPin ?? this.validatingPin,
        updatingPin: updatingPin ?? this.updatingPin,
        oldPinVerified: oldPinVerified,
        newPinConfirmed: newPinConfirmed,
        attemptsRemaining: attemptsRemaining ?? this.attemptsRemaining,
        blockedUntil: blockedUntil ?? this.blockedUntil,
        error: error ?? this.error,
        errorMessage: errorMessage ?? this.errorMessage);
  }

  @override
  String toString() {
    return 'ChangePinState {old pin: ${'*' * oldPin.length}, new pin: ${'*' * newPin.length}, validating pin: $validatingPin, udpating pin: $updatingPin, old verified: $oldPinVerified, new confirmed: $newPinConfirmed, attemptsRemaining: $attemptsRemaining, blockedUntil: $blockedUntil, error: $error, errorMessage: $errorMessage }';
  }

  @override
  List<Object?> get props {
    return [
      oldPin,
      newPin,
      validatingPin,
      updatingPin,
      oldPinVerified,
      newPinConfirmed,
      attemptsRemaining,
      blockedUntil,
      error,
      errorMessage
    ];
  }
}
