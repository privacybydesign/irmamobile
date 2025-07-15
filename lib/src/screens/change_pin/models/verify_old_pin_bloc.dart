import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/irma_repository.dart';
import '../../../models/authentication_events.dart';
import 'old_pin_verification_state.dart';
import 'validation_state.dart';

class VerifyOldPinBloc extends Bloc<String, OldPinVerificationState> {
  final IrmaRepository repo;
  VerifyOldPinBloc(this.repo) : super(const OldPinVerificationState());

  @override
  Stream<OldPinVerificationState> mapEventToState(String event) async* {
    final authenticationEvent = await repo.unlock(event);

    if (authenticationEvent is AuthenticationSuccessEvent) {
      yield const OldPinVerificationState(validationState: ValidationState.valid);
    } else if (authenticationEvent is AuthenticationFailedEvent) {
      yield OldPinVerificationState(
        validationState: ValidationState.invalid,
        attemptsRemaining: authenticationEvent.remainingAttempts,
        blockedUntil: DateTime.now().add(Duration(seconds: authenticationEvent.blockedDuration)),
      );
    } else if (authenticationEvent is AuthenticationErrorEvent) {
      yield OldPinVerificationState(validationState: ValidationState.error, error: authenticationEvent.error);
    } else {
      throw Exception('Unexpected subtype of AuthenticationResult');
    }
  }
}
