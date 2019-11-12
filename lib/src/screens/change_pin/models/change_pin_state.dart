import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

enum ValidationState { initial, valid, invalid }

@immutable
class ChangePinState with EquatableMixin {
  final String newPin;

  final int retry;

  final ValidationState oldPinVerified;
  final ValidationState newPinConfirmed;

  ChangePinState({
    this.newPin,
    this.oldPinVerified,
    this.newPinConfirmed,
    this.retry = 0,
  });

  ChangePinState copyWith(
      {String newPin,
      ValidationState oldPinVerified = ValidationState.initial,
      ValidationState newPinConfirmed = ValidationState.initial,
      int retry}) {
    return ChangePinState(
        newPin: newPin ?? this.newPin,
        oldPinVerified: oldPinVerified ?? this.oldPinVerified,
        newPinConfirmed: newPinConfirmed ?? this.newPinConfirmed,
        retry: retry ?? this.retry);
  }

  @override
  String toString() {
    return 'ChangePinState {new pin: ${newPin == null ? null : '*' * newPin.length}, old verified: $oldPinVerified, new confirmed: $newPinConfirmed, retry: $retry }';
  }

  @override
  List<Object> get props {
    return [newPin, oldPinVerified, newPinConfirmed, retry];
  }
}
