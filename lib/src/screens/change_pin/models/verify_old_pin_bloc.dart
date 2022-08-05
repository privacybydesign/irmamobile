import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/authentication_events.dart';
import 'package:irmamobile/src/screens/change_pin/models/validation_state.dart';

import 'old_pin_verification_state.dart';

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
      yield OldPinVerificationState(
        validationState: ValidationState.error,
        error: authenticationEvent.error,
      );
    } else {
      throw Exception('Unexpected subtype of AuthenticationResult');
    }
  }
}
