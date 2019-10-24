import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

enum ValidationState { initial, valid, invalid }

@immutable
class ChangePinState with EquatableMixin {
  final String newPin;

  final ValidationState oldPinVerified;
  final ValidationState newPinConfirmed;

  ChangePinState({
    this.newPin,
    this.oldPinVerified,
    this.newPinConfirmed,
  });

  ChangePinState copyWith({
    String newPin,
    ValidationState oldPinVerified = ValidationState.initial,
    ValidationState newPinConfirmed = ValidationState.initial,
  }) {
    return new ChangePinState(
      newPin: newPin ?? this.newPin,
      oldPinVerified: oldPinVerified ?? this.oldPinVerified,
      newPinConfirmed: newPinConfirmed ?? this.newPinConfirmed,
    );
  }

  @override
  String toString() {
    return 'ChangePinState {new pin: ${newPin == null ? null : '*' * newPin.length}, old verified: $oldPinVerified, new confirmed: $newPinConfirmed';
  }

  @override
  List<Object> get props {
    return [newPin, oldPinVerified, newPinConfirmed];
  }
}
