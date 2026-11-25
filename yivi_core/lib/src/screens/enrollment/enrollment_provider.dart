import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../data/irma_repository.dart";
import "../../models/enrollment_events.dart";
import "../../models/session.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/preferences_provider.dart";
import "../../util/serial_queue.dart";
import "../pin/providers/biometric_provider.dart";
import "enrollment_state.dart";

/// The enrollment, for as long as its screen shows: the PIN leaves memory
/// with the screen, and an enrollment after "delete everything" starts
/// fresh.
final enrollmentProvider =
    NotifierProvider.autoDispose<EnrollmentNotifier, EnrollmentState>(
      EnrollmentNotifier.new,
    );

/// The enrollment: the welcome page, then the numbered steps: the terms, a
/// PIN (twice), and Face ID when the device has it. The e-mail address is
/// linked later, from the app.
///
/// The account is made as soon as the PIN is confirmed, while Face ID shows.
/// "Setting up" only shows when the account is not there yet after the last
/// step.
///
/// Every action runs after the ones before it: a tap during the biometric
/// check waits for it, and then finds the next page.
class EnrollmentNotifier extends Notifier<EnrollmentState> {
  final _queue = SerialQueue();
  late IrmaRepository _repo;
  String _language = "en";

  String? _pin;
  var _offerBiometric = false;

  /// The account being made, from the moment the PIN is confirmed: null when
  /// it worked, else the error.
  Future<SessionError?>? _account;

  @override
  EnrollmentState build() {
    _repo = ref.read(irmaRepositoryProvider);
    return EnrollmentWelcome();
  }

  /// Completes with null once the account is made, or with the error.
  Future<SessionError?> get account => _account ?? _startAccount();

  Future<SessionError?> _startAccount() => _account = _repo
      .enroll(email: "", pin: _pin!, language: _language)
      .then((event) => event is EnrollmentFailureEvent ? event.error : null);

  /// The terms, error reports, the PIN, the PIN again, and Face ID when it
  /// is offered.
  int get _stepCount => 4 + (_offerBiometric ? 1 : 0);

  EnrollmentStepNumber get _termsStep => EnrollmentStepNumber(1, _stepCount);

  EnrollmentStepNumber get _errorsStep => EnrollmentStepNumber(2, _stepCount);

  EnrollmentStepNumber get _pinStep => EnrollmentStepNumber(3, _stepCount);

  EnrollmentStepNumber get _confirmStep => EnrollmentStepNumber(4, _stepCount);

  EnrollmentState _biometricOrDone() => _offerBiometric
      ? EnrollmentBiometric(step: EnrollmentStepNumber(5, _stepCount))
      : Enrolling();

  /// Runs [job] after every action before it.
  Future<void> _run(FutureOr<void> Function() job) => _queue.add(() async {
    if (!ref.mounted) return;
    await job();
  });

  /// Goes to [next], creating the account first when that is [Enrolling].
  Future<void> _goTo(EnrollmentState next) async {
    if (next is Enrolling) return _finish();
    state = next;
  }

  /// After the last step: the home screen once the account is there.
  Future<void> _finish() async {
    state = Enrolling();
    final error = await account;
    if (!ref.mounted) return;
    if (error == null) {
      state = EnrollmentCompleted();
    } else {
      state = EnrollmentFailed(error: error);
    }
  }

  /// Get started on the welcome page, in [language]: on to the terms.
  Future<void> next({required String language}) => _run(() async {
    if (state is! EnrollmentWelcome) return;
    _language = language;
    // Known now, so every step can say how many steps there are. Once, only
    // if a biometric is enrolled and the user hasn't chosen.
    final available = await ref.read(biometricAvailableProvider.future);
    if (!ref.mounted) return;
    _offerBiometric =
        available &&
        !ref.read(biometricEnabledProvider) &&
        !ref.read(biometricPromptDismissedProvider);
    state = EnrollmentTerms(step: _termsStep);
  });

  /// Accept and continue: the latest terms are accepted (which version, and
  /// when), on to error reports.
  void termsAccepted() => _run(() async {
    if (state is! EnrollmentTerms) return;
    await ref.read(preferencesProvider).acceptLatestTerms(true);
    if (!ref.mounted) return;
    state = EnrollmentErrorReports(step: _errorsStep);
  });

  /// Help improve Yivi?: Share reports ([share]) or Don't share. Stored as
  /// the error-report setting (also in Settings), then on to the PIN.
  void errorReportsChosen({required bool share}) => _run(() async {
    if (state is! EnrollmentErrorReports) return;
    await ref.read(preferencesProvider).reportErrors.set(share);
    if (!ref.mounted) return;
    state = EnrollmentChoosePin(step: _pinStep);
  });

  void back() => _run(() {
    switch (state) {
      case EnrollmentTerms():
        state = EnrollmentWelcome();
      case EnrollmentErrorReports():
        state = EnrollmentTerms(step: _termsStep);
      case EnrollmentChoosePin():
        state = EnrollmentErrorReports(step: _errorsStep);
      case EnrollmentConfirmPin():
        state = EnrollmentChoosePin(step: _pinStep);
      case EnrollmentFailed():
        // Start over from the PIN: the account was not made with this one.
        _account = null;
        state = EnrollmentChoosePin(step: _pinStep);
      default:
    }
  });

  void pinChosen(String pin) => _run(() {
    if (state is! EnrollmentChoosePin) return;
    _pin = pin;
    state = EnrollmentConfirmPin(step: _confirmStep);
  });

  /// The confirm screen compares the two PINs itself: a different one comes
  /// as [pinMismatch].
  void pinConfirmed(String pin) => _run(() async {
    if (state is! EnrollmentConfirmPin) return;
    unawaited(_startAccount());
    await _goTo(_biometricOrDone());
  });

  void pinMismatch() => _run(() {
    if (state is EnrollmentConfirmPin) {
      state = EnrollmentChoosePin(step: _pinStep);
    }
  });

  /// Face ID was turned on or declined: the page is done either way.
  void biometricDone() => _run(() async {
    if (state is EnrollmentBiometric) await _finish();
  });

  void retry() => _run(() async {
    state = Enrolling();
    final error = await _startAccount();
    if (!ref.mounted) return;
    state = error != null
        ? EnrollmentFailed(error: error)
        : EnrollmentCompleted();
  });
}
