import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../data/irma_repository.dart";
import "../../models/enrollment_events.dart";
import "../../models/session.dart";
import "../../providers/email_linking_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/preferences_provider.dart";
import "../../util/serial_queue.dart";
import "../pin/providers/biometric_provider.dart";
import "email/enrollment_email_link.dart";
import "enrollment_state.dart";

/// The enrollment, for as long as its screen shows: the PIN leaves memory
/// with the screen, and an enrollment after "delete everything" starts
/// fresh.
final enrollmentProvider =
    NotifierProvider.autoDispose<EnrollmentNotifier, EnrollmentState>(
      EnrollmentNotifier.new,
    );

/// The enrollment: the welcome page, a PIN (twice), Face ID when the device
/// has it, and the optional e-mail address.
///
/// The account is made as soon as the PIN is confirmed, while Face ID and
/// the e-mail step show: linking the address issues a credential, which
/// needs it. "Setting up" only shows when the account is not there yet
/// after the last step.
///
/// Every action runs after the ones before it: a tap during the biometric
/// check waits for it, and then finds the next page.
class EnrollmentNotifier extends Notifier<EnrollmentState> {
  final _queue = SerialQueue();
  late IrmaRepository _repo;
  String _language = "en";

  String? _pin;
  var _offerBiometric = false;
  var _offerEmail = false;

  /// The account being made, from the moment the PIN is confirmed: null when
  /// it worked, else the error.
  Future<SessionError?>? _account;

  /// Where to go once a failed account is made after all.
  EnrollmentState Function()? _afterRetry;

  /// Issues and links the e-mail address, from the moment the PIN is
  /// confirmed. Owned here, so a link in progress finishes even if the
  /// e-mail page goes.
  EnrollmentEmailLink? _emailLink;

  @override
  EnrollmentState build() {
    _repo = ref.read(irmaRepositoryProvider);
    return EnrollmentWelcome();
  }

  /// Completes with null once the account is made, or with the error.
  Future<SessionError?> get account => _account ?? _startAccount();

  /// The e-mail link of this enrollment, once the PIN is confirmed.
  EnrollmentEmailLink? get emailLink => _emailLink;

  Future<SessionError?> _startAccount() => _account = _repo
      .enroll(email: "", pin: _pin!, language: _language)
      .then((event) => event is EnrollmentFailureEvent ? event.error : null);

  int get _stepCount => 1 + (_offerBiometric ? 1 : 0) + (_offerEmail ? 1 : 0);

  EnrollmentStepNumber? get _pinStep =>
      _stepCount > 1 ? EnrollmentStepNumber(1, _stepCount) : null;

  EnrollmentState _biometricOrNext() => _offerBiometric
      ? EnrollmentBiometric(step: EnrollmentStepNumber(2, _stepCount))
      : _emailOrDone();

  EnrollmentState _emailOrDone() => _offerEmail
      ? EnrollmentEmail(step: EnrollmentStepNumber(_stepCount, _stepCount))
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
      _afterRetry = EnrollmentCompleted.new;
      state = EnrollmentFailed(error: error);
    }
  }

  void setTermsAccepted(bool accepted) => _run(() {
    if (state is EnrollmentWelcome) {
      state = EnrollmentWelcome(isAccepted: accepted);
    }
  });

  /// Continue on the welcome page, in [language].
  Future<void> next({required String language}) => _run(() async {
    final current = state;
    if (current is! EnrollmentWelcome || !current.isAccepted) return;
    _language = language;
    // Known now, so the PIN steps can say how many steps there are. Once,
    // only if a biometric is enrolled and the user hasn't chosen.
    final available = await ref.read(biometricAvailableProvider.future);
    if (!ref.mounted) return;
    _offerBiometric =
        available &&
        !ref.read(biometricEnabledProvider) &&
        !ref.read(biometricPromptDismissedProvider);
    _offerEmail = ref.read(emailLinkingOfferedProvider);
    state = EnrollmentChoosePin(step: _pinStep);
  });

  void back() => _run(() {
    switch (state) {
      case EnrollmentChoosePin():
        state = EnrollmentWelcome(isAccepted: true);
      case EnrollmentConfirmPin():
        state = EnrollmentChoosePin(step: _pinStep);
      case EnrollmentFailed():
        // Start over from the PIN: the account was not made with this one.
        _account = null;
        _afterRetry = null;
        state = EnrollmentChoosePin(step: _pinStep);
      default:
    }
  });

  void pinChosen(String pin) => _run(() {
    if (state is! EnrollmentChoosePin) return;
    _pin = pin;
    state = EnrollmentConfirmPin(step: _pinStep);
  });

  /// The confirm screen compares the two PINs itself: a different one comes
  /// as [pinMismatch].
  void pinConfirmed(String pin) => _run(() async {
    if (state is! EnrollmentConfirmPin) return;
    unawaited(_startAccount());
    final prefs = ref.read(preferencesProvider);
    _emailLink = EnrollmentEmailLink(
      repo: _repo,
      pin: _pin!,
      api: ref.read(keyshareEmailLinkApiProvider),
      markLinked: () => prefs.emailLinked.set(true),
    );
    await _goTo(_biometricOrNext());
  });

  void pinMismatch() => _run(() {
    if (state is EnrollmentConfirmPin) {
      state = EnrollmentChoosePin(step: _pinStep);
    }
  });

  /// Face ID was turned on or declined: the page is done either way.
  void biometricDone() => _run(() async {
    if (state is EnrollmentBiometric) await _goTo(_emailOrDone());
  });

  /// The e-mail step was skipped, or the address is linked.
  void emailDone() => _run(() async {
    if (state is EnrollmentEmail) await _finish();
  });

  /// The e-mail step needs the account, and it could not be made.
  void accountFailed(SessionError error) => _run(() {
    _afterRetry = _emailOrDone;
    state = EnrollmentFailed(error: error);
  });

  void retry() => _run(() async {
    state = Enrolling();
    final error = await _startAccount();
    if (!ref.mounted) return;
    state = error != null
        ? EnrollmentFailed(error: error)
        : (_afterRetry ?? EnrollmentCompleted.new)();
  });
}
