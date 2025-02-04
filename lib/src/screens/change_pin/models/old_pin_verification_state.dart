import 'package:flutter/widgets.dart';

import '../../../models/session.dart';
import 'validation_state.dart';

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
