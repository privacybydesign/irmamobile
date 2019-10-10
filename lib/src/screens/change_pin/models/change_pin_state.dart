import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class ChangePinState with EquatableMixinBase, EquatableMixin {
  final String newPin;

  // This value is null initially.
  // When the old pin is entered correctly this value will be true
  // When the old pin is entered incorrectly this value will be false
  final bool oldPinVerified;

  // This value is null initially.
  // When the new pin is confirmed this value will be true
  // When the confirm pin did not match this value will be false
  final bool newPinConfirmed;

  ChangePinState({
    this.newPin,
    this.oldPinVerified,
    this.newPinConfirmed,
  });

  ChangePinState copyWith({
    String newPin,
    bool oldPinVerified,
    bool newPinConfirmed,
  }) {
    return new ChangePinState(
      newPin: newPin ?? this.newPin,
      oldPinVerified: oldPinVerified ?? this.oldPinVerified,
      newPinConfirmed: newPinConfirmed ?? this.newPinConfirmed,
    );
  }

  @override
  String toString() {
    if (newPin == null) {
      return 'ChangePinState {pin: <null>}';
    }

    final String code = '*' * newPin.length;

    return 'ChangePinState {pin: $code}';
  }

  @override
  List<Object> get props {
    return [newPin, oldPinVerified, newPinConfirmed];
  }
}
