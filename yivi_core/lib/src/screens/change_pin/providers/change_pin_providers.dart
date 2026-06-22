import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../models/authentication_events.dart";
import "../../../models/change_pin_events.dart";
import "../../../models/session.dart";
import "../../../providers/irma_repository_provider.dart";
import "../models/change_pin_state.dart";
import "../models/old_pin_verification_state.dart";
import "../models/validation_state.dart";

/// Verifies the user's current PIN against the keyshare server before letting
/// them choose a new one. Replaces `VerifyOldPinBloc`. `autoDispose` so the
/// state is fresh each time the change-pin flow is opened.
class VerifyOldPinNotifier extends Notifier<OldPinVerificationState> {
  @override
  OldPinVerificationState build() => const OldPinVerificationState();

  Future<void> verify(String pin) async {
    final repo = ref.read(irmaRepositoryProvider);
    final event = await repo.unlock(pin);

    state = switch (event) {
      AuthenticationSuccessEvent() => const OldPinVerificationState(
        validationState: ValidationState.valid,
      ),
      AuthenticationFailedEvent(:final remainingAttempts, :final blockedDuration) =>
        OldPinVerificationState(
          validationState: ValidationState.invalid,
          attemptsRemaining: remainingAttempts,
          blockedUntil: DateTime.now().add(
            Duration(seconds: blockedDuration),
          ),
        ),
      AuthenticationErrorEvent(:final error) => OldPinVerificationState(
        validationState: ValidationState.error,
        error: error,
      ),
      _ => throw Exception("Unexpected subtype of AuthenticationResult"),
    };
  }
}

final verifyOldPinProvider =
    NotifierProvider.autoDispose<VerifyOldPinNotifier, OldPinVerificationState>(
      VerifyOldPinNotifier.new,
    );

/// Holds the old/new PIN through the change-pin flow and commits the change.
/// Replaces `ChangePinBloc`.
class ChangePinNotifier extends Notifier<ChangePinState> {
  @override
  ChangePinState build() => const ChangePinState();

  void setOldPin(String pin) => state = state.copyWith(oldPin: pin);
  void setNewPin(String pin) => state = state.copyWith(newPin: pin);

  Future<void> confirmNewPin() async {
    final repo = ref.read(irmaRepositoryProvider);
    final event = await repo.changePin(state.oldPin, state.newPin);

    state = switch (event) {
      ChangePinSuccessEvent() => state.copyWith(
        newPinConfirmed: ValidationState.valid,
      ),
      ChangePinErrorEvent(:final error) => state.copyWith(
        newPinConfirmed: ValidationState.error,
        error: error,
      ),
      ChangePinFailedEvent() => state.copyWith(
        newPinConfirmed: ValidationState.error,
        error: SessionError(
          errorType: "Unexpected Error",
          info: "Unexpected old pin rejection by server",
        ),
      ),
      _ => state,
    };
  }
}

final changePinProvider =
    NotifierProvider.autoDispose<ChangePinNotifier, ChangePinState>(
      ChangePinNotifier.new,
    );
