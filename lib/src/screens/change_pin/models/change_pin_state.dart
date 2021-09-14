// This code is not null safe yet.
// @dart=2.11

import 'package:equatable/equatable.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:meta/meta.dart';

enum ValidationState { initial, valid, invalid, error }

@immutable
class ChangePinState with EquatableMixin {
  final String newPin;
  final String oldPin;
  final bool longPin;
  final bool validatingPin;
  final bool updatingPin;

  final int attemptsRemaining;
  final DateTime blockedUntil;
  final SessionError error;
  final String errorMessage;

  final ValidationState oldPinVerified;
  final ValidationState newPinConfirmed;

  ChangePinState({
    this.oldPin,
    this.newPin,
    this.longPin = false,
    this.validatingPin = false,
    this.updatingPin = false,
    this.oldPinVerified,
    this.newPinConfirmed,
    this.attemptsRemaining = 0,
    this.blockedUntil,
    this.error,
    this.errorMessage,
  });

  ChangePinState copyWith(
      {String oldPin,
      String newPin,
      bool longPin,
      bool validatingPin,
      bool updatingPin,
      ValidationState oldPinVerified = ValidationState.initial,
      ValidationState newPinConfirmed = ValidationState.initial,
      int attemptsRemaining,
      DateTime blockedUntil,
      SessionError error,
      String errorMessage}) {
    return ChangePinState(
        oldPin: oldPin ?? this.oldPin,
        newPin: newPin ?? this.newPin,
        longPin: longPin ?? this.longPin,
        validatingPin: validatingPin ?? this.validatingPin,
        updatingPin: updatingPin ?? this.updatingPin,
        oldPinVerified: oldPinVerified ?? this.oldPinVerified,
        newPinConfirmed: newPinConfirmed ?? this.newPinConfirmed,
        attemptsRemaining: attemptsRemaining ?? this.attemptsRemaining,
        blockedUntil: blockedUntil ?? this.blockedUntil,
        error: error ?? this.error,
        errorMessage: errorMessage ?? this.errorMessage);
  }

  @override
  String toString() {
    return 'ChangePinState {old pin: ${oldPin == null ? null : '*' * oldPin.length}, new pin: ${newPin == null ? null : '*' * newPin.length}, long pin: $longPin, validating pin: $validatingPin, udpating pin: $updatingPin, old verified: $oldPinVerified, new confirmed: $newPinConfirmed, attemptsRemaining: $attemptsRemaining, blockedUntil: $blockedUntil, error: $error, errorMessage: $errorMessage }';
  }

  @override
  List<Object> get props {
    return [
      oldPin,
      newPin,
      longPin,
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
