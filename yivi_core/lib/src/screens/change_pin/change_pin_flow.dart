import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../models/authentication_events.dart";
import "../../models/change_pin_events.dart";
import "../../models/session.dart";
import "../../providers/irma_repository_provider.dart";
import "../../util/haptics.dart";
import "../pin/pin_feedback.dart";

/// Where Change PIN is.
sealed class ChangePinStep {
  const ChangePinStep();
}

/// The current PIN, asked again after a wrong one.
final class EnterOldPin extends ChangePinStep {
  const EnterOldPin({this.feedback = const PinFeedback()});
  final PinFeedback feedback;
}

/// A new PIN. [round] goes up after a mismatch: a fresh page.
final class ChooseNewPin extends ChangePinStep {
  const ChooseNewPin({this.previous = "", this.round = 0});

  /// The PIN chosen before a mismatch: it says long or short.
  final String previous;
  final int round;
}

/// The new PIN again, over [choose].
final class ConfirmNewPin extends ChangePinStep {
  const ConfirmNewPin(this.chosen, {required this.choose});
  final String chosen;
  final ChooseNewPin choose;
}

/// An error over [back], where its close goes.
final class ChangePinFailed extends ChangePinStep {
  const ChangePinFailed(this.error, {required this.back});
  final SessionError? error;
  final ChangePinStep back;
}

/// Out of tries: the app locks until [until].
final class ChangePinBlocked extends ChangePinStep {
  const ChangePinBlocked(this.until);
  final DateTime until;
}

final class ChangePinDone extends ChangePinStep {
  const ChangePinDone();
}

/// Change PIN: check the current PIN, choose a new one, confirm it, send.
class ChangePinFlow extends Notifier<ChangePinStep> {
  /// Never in the state.
  String _oldPin = "";

  @override
  ChangePinStep build() => const EnterOldPin();

  Future<void> submitOld(String pin) async {
    final repo = ref.read(irmaRepositoryProvider);
    final before = state is EnterOldPin
        ? (state as EnterOldPin).feedback
        : const PinFeedback();
    final event = await repo.unlock(pin);
    if (!ref.mounted) return;
    switch (event) {
      case AuthenticationSuccessEvent():
        Haptics.success();
        _oldPin = pin;
        state = const ChooseNewPin();
      case AuthenticationFailedEvent(
        :final remainingAttempts,
        :final blockedDuration,
      ):
        Haptics.error();
        if (remainingAttempts <= 0) {
          final until = DateTime.now().add(Duration(seconds: blockedDuration));
          state = ChangePinBlocked(until);
          repo.lock(unblockTime: until);
        } else {
          // The enter page again, saying it was wrong.
          state = EnterOldPin(
            feedback: PinFeedback(
              wrongCount: before.wrongCount + 1,
              wrong: true,
              left: remainingAttempts,
            ),
          );
        }
      case AuthenticationErrorEvent(:final error):
        Haptics.error();
        state = ChangePinFailed(error, back: EnterOldPin(feedback: before));
      default:
        throw Exception("Unexpected subtype of AuthenticationResult");
    }
  }

  void choose(String pin) {
    final choosing = state;
    if (choosing is ChooseNewPin) state = ConfirmNewPin(pin, choose: choosing);
  }

  /// The confirmation was another PIN: choose again, on a fresh page.
  void mismatch() {
    final confirming = state;
    if (confirming is! ConfirmNewPin) return;
    state = ChooseNewPin(
      previous: confirming.chosen,
      round: confirming.choose.round + 1,
    );
  }

  /// Back from confirming: the choose page as it was.
  void backToChoose() {
    final confirming = state;
    if (confirming is ConfirmNewPin) state = confirming.choose;
  }

  Future<void> commit(String newPin) async {
    final confirming = state;
    if (confirming is! ConfirmNewPin) return;
    final event = await ref
        .read(irmaRepositoryProvider)
        .changePin(_oldPin, newPin);
    if (!ref.mounted) return;
    state = switch (event) {
      ChangePinSuccessEvent() => const ChangePinDone(),
      ChangePinErrorEvent(:final error) => ChangePinFailed(
        error,
        back: confirming.choose,
      ),
      ChangePinFailedEvent() => ChangePinFailed(
        SessionError(
          errorType: "Unexpected Error",
          info: "Unexpected old pin rejection by server",
        ),
        back: confirming.choose,
      ),
      _ => state,
    };
  }

  void closeError() {
    final failed = state;
    if (failed is ChangePinFailed) state = failed.back;
  }
}

final changePinFlowProvider =
    NotifierProvider.autoDispose<ChangePinFlow, ChangePinStep>(
      ChangePinFlow.new,
    );
