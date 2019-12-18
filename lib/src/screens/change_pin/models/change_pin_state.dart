import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

enum ValidationState { initial, valid, invalid }

@immutable
class ChangePinState with EquatableMixin {
  final String newPin;
  final bool longPin;
  final bool validatingPin;

  final int retry;

  final ValidationState oldPinVerified;
  final ValidationState newPinConfirmed;

  ChangePinState({
    this.newPin,
    this.longPin = false,
    this.validatingPin = false,
    this.oldPinVerified,
    this.newPinConfirmed,
    this.retry = 0,
  });

  ChangePinState copyWith(
      {String newPin,
      bool longPin,
      bool validatingPin,
      ValidationState oldPinVerified = ValidationState.initial,
      ValidationState newPinConfirmed = ValidationState.initial,
      int retry}) {
    return ChangePinState(
        newPin: newPin ?? this.newPin,
        longPin: longPin ?? this.longPin,
        validatingPin: validatingPin ?? this.validatingPin,
        oldPinVerified: oldPinVerified ?? this.oldPinVerified,
        newPinConfirmed: newPinConfirmed ?? this.newPinConfirmed,
        retry: retry ?? this.retry);
  }

  @override
  String toString() {
    return 'ChangePinState {new pin: ${newPin == null ? null : '*' * newPin.length}, long pin: $longPin, validating pin: $validatingPin, old verified: $oldPinVerified, new confirmed: $newPinConfirmed, retry: $retry }';
  }

  @override
  List<Object> get props {
    return [newPin, longPin, validatingPin, oldPinVerified, newPinConfirmed, retry];
  }
}
