import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/screens/change_pin/models/validation_state.dart';
import 'package:meta/meta.dart';

@immutable
class OldPinVerificationState {
  final ValidationState validationState;
  final int? attemptsRemaining;
  final DateTime? blockedUntil;
  final SessionError? error;

  const OldPinVerificationState({
    this.validationState = ValidationState.initial,
    this.attemptsRemaining,
    this.blockedUntil,
    this.error,
  });
}
