import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";

import "../../../data/irma_repository.dart";
import "../../../models/enrollment_events.dart";
import "../../../models/session.dart";

part "enrollment_event.dart";
part "enrollment_state.dart";

/// The enrollment: the welcome page, a PIN (twice), Face ID when the device
/// has it, and the optional e-mail address.
///
/// The account is made as soon as the PIN is confirmed, while Face ID and the
/// e-mail step show: linking the address issues a credential, which needs it.
/// "Setting up" only shows when the account is not there yet after the last
/// step.
class EnrollmentBloc extends Bloc<EnrollmentBlocEvent, EnrollmentState> {
  final String language;
  final IrmaRepository repo;

  /// Whether to offer Face ID, Touch ID or the fingerprint: the device has
  /// one enrolled and the user has not chosen yet.
  final Future<bool> Function() biometricOffered;

  /// Whether the e-mail step can link an address (the keyshare server's link
  /// endpoint is known).
  final bool Function() emailOffered;

  String? _pin;
  var _offerBiometric = false;
  var _offerEmail = false;

  /// The account being made, from the moment the PIN is confirmed: null when
  /// it worked, else the error.
  Future<SessionError?>? _account;

  /// Where to go once a failed account is made after all.
  EnrollmentState Function()? _afterRetry;

  EnrollmentBloc({
    required this.language,
    required this.repo,
    required this.biometricOffered,
    required this.emailOffered,
  }) : super(EnrollmentWelcome());

  /// The PIN chosen in this enrollment, for the sessions of the e-mail step,
  /// which would otherwise ask for it again. Never stored.
  String? get pin => _pin;

  /// Completes with null once the account is made, or with the error.
  Future<SessionError?> get account => _account ?? _startAccount();

  Future<SessionError?> _startAccount() {
    return _account = repo
        .enroll(email: "", pin: _pin!, language: language)
        .then((event) => event is EnrollmentFailureEvent ? event.error : null);
  }

  int get _stepCount => 1 + (_offerBiometric ? 1 : 0) + (_offerEmail ? 1 : 0);

  EnrollmentStepNumber? get _pinStep =>
      _stepCount > 1 ? EnrollmentStepNumber(1, _stepCount) : null;

  EnrollmentState _biometricOrNext() => _offerBiometric
      ? EnrollmentBiometric(step: EnrollmentStepNumber(2, _stepCount))
      : _emailOrDone();

  EnrollmentState _emailOrDone() => _offerEmail
      ? EnrollmentEmail(step: EnrollmentStepNumber(_stepCount, _stepCount))
      : Enrolling();

  /// After the last step: the home screen once the account is there.
  Stream<EnrollmentState> _finish() async* {
    yield Enrolling();
    final error = await account;
    if (error == null) {
      yield EnrollmentCompleted();
    } else {
      _afterRetry = EnrollmentCompleted.new;
      yield EnrollmentFailed(error: error);
    }
  }

  @override
  Stream<EnrollmentState> mapEventToState(EnrollmentBlocEvent event) async* {
    final state = this.state; // To prevent the need for type casting.

    if (event is EnrollmentRetried) {
      yield Enrolling();
      final error = await _startAccount();
      if (error != null) {
        yield EnrollmentFailed(error: error);
      } else {
        yield (_afterRetry ?? EnrollmentCompleted.new)();
      }
    } else if (event is EnrollmentAccountFailed) {
      _afterRetry = _emailOrDone;
      yield EnrollmentFailed(error: event.error);
    } else if (state is EnrollmentWelcome) {
      if (event is EnrollmentTermsUpdated) {
        yield EnrollmentWelcome(isAccepted: event.isAccepted);
      } else if (event is EnrollmentNextPressed) {
        if (!state.isAccepted) {
          throw ("Continuing without accepting the terms is not possible");
        }
        // Known now, so the PIN steps can say how many steps there are.
        _offerBiometric = await biometricOffered();
        _offerEmail = emailOffered();
        yield EnrollmentChoosePin(step: _pinStep);
      }
    } else if (state is EnrollmentChoosePin) {
      if (event is EnrollmentPinChosen) {
        _pin = event.pin;
        yield EnrollmentConfirmPin(step: _pinStep);
      } else if (event is EnrollmentPreviousPressed) {
        yield EnrollmentWelcome(isAccepted: true);
      }
    } else if (state is EnrollmentConfirmPin) {
      if (event is EnrollmentPinMismatch) {
        yield EnrollmentChoosePin(step: _pinStep);
      } else if (event is EnrollmentPinConfirmed) {
        if (_pin == event.pin) {
          unawaited(_startAccount());
          final next = _biometricOrNext();
          if (next is Enrolling) {
            yield* _finish();
          } else {
            yield next;
          }
        } else {
          yield EnrollmentConfirmPin(step: _pinStep, confirmationFailed: true);
        }
      } else if (event is EnrollmentPreviousPressed) {
        yield EnrollmentChoosePin(step: _pinStep);
      }
    } else if (state is EnrollmentBiometric &&
        event is EnrollmentBiometricDone) {
      final next = _emailOrDone();
      if (next is Enrolling) {
        yield* _finish();
      } else {
        yield next;
      }
    } else if (state is EnrollmentEmail && event is EnrollmentEmailDone) {
      yield* _finish();
    } else if (state is EnrollmentFailed &&
        event is EnrollmentPreviousPressed) {
      // Start over from the PIN: the account was not made with this one.
      _account = null;
      _afterRetry = null;
      yield EnrollmentChoosePin(step: _pinStep);
    }
  }
}
