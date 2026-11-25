import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/screens/enrollment/enrollment_provider.dart";
import "package:yivi_core/src/screens/enrollment/enrollment_state.dart";
import "package:yivi_core/src/screens/pin/providers/biometric_provider.dart";

import "support/onboarding_v2_harness.dart";

SessionError _error() => SessionError(errorType: "transport", info: "offline");

// What the user does, as the steps of the enrollment report it.
sealed class _Action {}

class EnrollmentTermsUpdated extends _Action {
  final bool isAccepted;
  EnrollmentTermsUpdated({required this.isAccepted});
}

class EnrollmentNextPressed extends _Action {}

class EnrollmentTermsContinued extends _Action {}

class EnrollmentPreviousPressed extends _Action {}

class EnrollmentPinChosen extends _Action {
  final String pin;
  EnrollmentPinChosen(this.pin);
}

class EnrollmentPinConfirmed extends _Action {
  final String pin;
  EnrollmentPinConfirmed(this.pin);
}

class EnrollmentPinMismatch extends _Action {}

class EnrollmentBiometricDone extends _Action {}

class EnrollmentRetried extends _Action {}

/// Drives the enrollment notifier: an action in, the states out.
class _Enrollment {
  _Enrollment(this._container) {
    _sub = _container.listen(enrollmentProvider, (_, s) => _states.add(s));
  }

  final ProviderContainer _container;
  late final ProviderSubscription<EnrollmentState> _sub;
  final _states = StreamController<EnrollmentState>.broadcast();

  EnrollmentNotifier get _n => _container.read(enrollmentProvider.notifier);

  Stream<EnrollmentState> get stream => _states.stream;
  EnrollmentState get state => _container.read(enrollmentProvider);
  Future<SessionError?> get account => _n.account;

  void add(_Action action) => switch (action) {
    EnrollmentTermsUpdated(:final isAccepted) => _n.setTermsAccepted(
      isAccepted,
    ),
    EnrollmentNextPressed() => _n.next(language: "en"),
    EnrollmentTermsContinued() => _n.termsAccepted(),
    EnrollmentPreviousPressed() => _n.back(),
    EnrollmentPinChosen(:final pin) => _n.pinChosen(pin),
    EnrollmentPinConfirmed(:final pin) => _n.pinConfirmed(pin),
    EnrollmentPinMismatch() => _n.pinMismatch(),
    EnrollmentBiometricDone() => _n.biometricDone(),
    EnrollmentRetried() => _n.retry(),
  };

  Future<void> close() async {
    _sub.close();
    _container.dispose();
    await _states.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingBridge bridge;
  late IrmaRepository repo;

  /// Whether the next enrollment works; a test can hold it back.
  var enrollWorks = true;
  Completer<void>? holdEnrollment;

  setUp(() async {
    enrollWorks = true;
    holdEnrollment = null;
    bridge = RecordingBridge();
    bridge.respond = (event) {
      if (event is! EnrollEvent) return null;
      final reply = enrollWorks
          ? EnrollmentSuccessEvent(schemeManagerID: "pbdf")
          : EnrollmentFailureEvent(schemeManagerID: "pbdf", error: _error());
      final hold = holdEnrollment;
      if (hold == null) return reply;
      hold.future.then((_) => bridge.deliver(reply));
      return null;
    };
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  _Enrollment newEnrollment({
    bool biometric = true,
    Future<bool>? biometricCheck,
  }) {
    final enrollment = _Enrollment(
      ProviderContainer(
        overrides: [
          irmaRepositoryProvider.overrideWithValue(repo),
          preferencesProvider.overrideWithValue(repo.preferences),
          biometricAvailableProvider.overrideWith(
            (ref) => biometricCheck ?? Future.value(biometric),
          ),
        ],
      ),
    );
    addTearDown(enrollment.close);
    return enrollment;
  }

  Future<EnrollmentState> next(_Enrollment enrollment, _Action e) {
    final state = enrollment.stream.first;
    enrollment.add(e);
    return state;
  }

  /// Through the welcome page and the terms, to the PIN.
  Future<EnrollmentState> toPin(_Enrollment enrollment) async {
    await next(enrollment, EnrollmentNextPressed());
    await next(enrollment, EnrollmentTermsUpdated(isAccepted: true));
    return next(enrollment, EnrollmentTermsContinued());
  }

  /// Through the welcome page, the terms and both PIN pages.
  Future<EnrollmentState> toAfterPin(_Enrollment enrollment) async {
    await toPin(enrollment);
    await next(enrollment, EnrollmentPinChosen("12345"));
    return next(enrollment, EnrollmentPinConfirmed("12345"));
  }

  int enrollments() => bridge.dispatched.whereType<EnrollEvent>().length;

  test("the steps are numbered: terms, PIN, PIN again, Face ID", () async {
    final enrollment = newEnrollment();
    final terms = await next(enrollment, EnrollmentNextPressed());
    expect(terms, isA<EnrollmentTerms>());
    expect((terms as EnrollmentTerms).step.number, 1);
    expect(terms.step.total, 4);
    expect(terms.isAccepted, isFalse);

    await next(enrollment, EnrollmentTermsUpdated(isAccepted: true));
    final pin = await next(enrollment, EnrollmentTermsContinued());
    expect(pin, isA<EnrollmentChoosePin>());
    expect((pin as EnrollmentChoosePin).step?.number, 2);

    final confirm = await next(enrollment, EnrollmentPinChosen("12345"));
    expect((confirm as EnrollmentConfirmPin).step?.number, 3);
    final bio = await next(enrollment, EnrollmentPinConfirmed("12345"));
    expect(bio, isA<EnrollmentBiometric>());
    expect((bio as EnrollmentBiometric).step.number, 4);

    expect(bio.step.total, 4);
  });

  test("Continue on the terms needs them accepted", () async {
    final enrollment = newEnrollment();
    await next(enrollment, EnrollmentNextPressed());
    enrollment.add(EnrollmentTermsContinued());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(enrollment.state, isA<EnrollmentTerms>());

    await next(enrollment, EnrollmentTermsUpdated(isAccepted: true));
    expect(
      await next(enrollment, EnrollmentTermsContinued()),
      isA<EnrollmentChoosePin>(),
    );
  });

  test(
    "terms ticked once stay ticked after going back to the welcome page",
    () async {
      final enrollment = newEnrollment();
      await toPin(enrollment);
      await next(enrollment, EnrollmentPreviousPressed());
      await next(enrollment, EnrollmentPreviousPressed());
      final terms = await next(enrollment, EnrollmentNextPressed());
      expect((terms as EnrollmentTerms).isAccepted, isTrue);
    },
  );

  test("back: PIN to the accepted terms, terms to the welcome page", () async {
    final enrollment = newEnrollment();
    await toPin(enrollment);
    final terms = await next(enrollment, EnrollmentPreviousPressed());
    expect((terms as EnrollmentTerms).isAccepted, isTrue);
    expect(
      await next(enrollment, EnrollmentPreviousPressed()),
      isA<EnrollmentWelcome>(),
    );
  });

  test("the account is made as soon as the PIN is confirmed, without an "
      "address", () async {
    final enrollment = newEnrollment();
    await toAfterPin(enrollment);

    expect(enrollments(), 1);
    final enroll = bridge.dispatched.whereType<EnrollEvent>().single;
    expect(enroll.email, "");
    expect(enroll.pin, "12345");
    expect(await enrollment.account, isNull);
  });

  test("Face ID is the last step", () async {
    final enrollment = newEnrollment();
    final bio = await toAfterPin(enrollment);
    expect((bio as EnrollmentBiometric).step.total, 4);

    enrollment.add(EnrollmentBiometricDone());
    await expectLater(
      enrollment.stream,
      emitsInOrder([isA<Enrolling>(), isA<EnrollmentCompleted>()]),
    );
  });

  test("without Face ID there are 3 steps and the app is set up straight "
      "after the PIN", () async {
    final enrollment = newEnrollment(biometric: false);
    final pin = await toPin(enrollment);
    expect((pin as EnrollmentChoosePin).step?.total, 3);

    await next(enrollment, EnrollmentPinChosen("12345"));
    enrollment.add(EnrollmentPinConfirmed("12345"));
    await expectLater(
      enrollment.stream,
      emitsInOrder([isA<Enrolling>(), isA<EnrollmentCompleted>()]),
    );
  });

  test("a failed account at the end can be retried", () async {
    enrollWorks = false;
    final enrollment = newEnrollment(biometric: false);
    await toPin(enrollment);
    await next(enrollment, EnrollmentPinChosen("12345"));
    enrollment.add(EnrollmentPinConfirmed("12345"));
    await expectLater(
      enrollment.stream,
      emitsInOrder([isA<Enrolling>(), isA<EnrollmentFailed>()]),
    );

    enrollWorks = true;
    enrollment.add(EnrollmentRetried());
    await expectLater(
      enrollment.stream,
      emitsInOrder([isA<Enrolling>(), isA<EnrollmentCompleted>()]),
    );
    expect(enrollments(), 2);
  });

  test("back from a failure starts over at the PIN", () async {
    enrollWorks = false;
    final enrollment = newEnrollment(biometric: false);
    await toPin(enrollment);
    await next(enrollment, EnrollmentPinChosen("12345"));
    enrollment.add(EnrollmentPinConfirmed("12345"));
    await expectLater(
      enrollment.stream,
      emitsInOrder([isA<Enrolling>(), isA<EnrollmentFailed>()]),
    );

    expect(
      await next(enrollment, EnrollmentPreviousPressed()),
      isA<EnrollmentChoosePin>(),
    );
  });

  test(
    "a different second PIN chooses again, without making an account",
    () async {
      final enrollment = newEnrollment();
      await toPin(enrollment);
      await next(enrollment, EnrollmentPinChosen("12345"));
      // The confirm screen compares the PINs and reports the mismatch.
      final again = await next(enrollment, EnrollmentPinMismatch());

      expect(again, isA<EnrollmentChoosePin>());
      expect(enrollments(), 0);
    },
  );

  test("a second Get started during the biometric check is ignored", () async {
    final check = Completer<bool>();
    final enrollment = newEnrollment(biometricCheck: check.future);
    final states = <EnrollmentState>[];
    final sub = enrollment.stream.listen(states.add);
    addTearDown(sub.cancel);
    enrollment.add(EnrollmentNextPressed());
    enrollment.add(EnrollmentNextPressed());
    await Future<void>.delayed(Duration.zero);
    check.complete(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(enrollment.state, isA<EnrollmentTerms>());
    expect(states.whereType<EnrollmentTerms>().length, 1);
  });

  test("ticking the terms on the welcome page does nothing", () async {
    final enrollment = newEnrollment();
    enrollment.add(EnrollmentTermsUpdated(isAccepted: true));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(enrollment.state, isA<EnrollmentWelcome>());
  });
}
