import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/email_linking_provider.dart";
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

class EnrollmentEmailDone extends _Action {}

class EnrollmentAccountFailed extends _Action {
  final SessionError error;
  EnrollmentAccountFailed(this.error);
}

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
  String? get pin => _n.emailLink?.pin;

  void add(_Action action) => switch (action) {
    EnrollmentTermsUpdated(:final isAccepted) => _n.setTermsAccepted(
      isAccepted,
    ),
    EnrollmentNextPressed() => _n.next(language: "en"),
    EnrollmentPreviousPressed() => _n.back(),
    EnrollmentPinChosen(:final pin) => _n.pinChosen(pin),
    EnrollmentPinConfirmed(:final pin) => _n.pinConfirmed(pin),
    EnrollmentPinMismatch() => _n.pinMismatch(),
    EnrollmentBiometricDone() => _n.biometricDone(),
    EnrollmentEmailDone() => _n.emailDone(),
    EnrollmentAccountFailed(:final error) => _n.accountFailed(error),
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

  _Enrollment newBloc({
    bool biometric = true,
    bool email = true,
    Future<bool>? biometricCheck,
  }) {
    final bloc = _Enrollment(
      ProviderContainer(
        overrides: [
          irmaRepositoryProvider.overrideWithValue(repo),
          preferencesProvider.overrideWithValue(repo.preferences),
          biometricAvailableProvider.overrideWith(
            (ref) => biometricCheck ?? Future.value(biometric),
          ),
          emailLinkingOfferedProvider.overrideWithValue(email),
        ],
      ),
    );
    addTearDown(bloc.close);
    return bloc;
  }

  Future<EnrollmentState> next(_Enrollment bloc, _Action e) {
    final state = bloc.stream.first;
    bloc.add(e);
    return state;
  }

  /// Through the welcome page and both PIN pages.
  Future<EnrollmentState> toAfterPin(_Enrollment bloc) async {
    await next(bloc, EnrollmentTermsUpdated(isAccepted: true));
    await next(bloc, EnrollmentNextPressed());
    await next(bloc, EnrollmentPinChosen("12345"));
    return next(bloc, EnrollmentPinConfirmed("12345"));
  }

  int enrollments() => bridge.dispatched.whereType<EnrollEvent>().length;

  test("the steps are numbered: PIN, Face ID, e-mail", () async {
    final bloc = newBloc();
    await next(bloc, EnrollmentTermsUpdated(isAccepted: true));
    final pin = await next(bloc, EnrollmentNextPressed());
    expect(pin, isA<EnrollmentChoosePin>());
    expect((pin as EnrollmentChoosePin).step?.number, 1);
    expect(pin.step?.total, 3);

    await next(bloc, EnrollmentPinChosen("12345"));
    final bio = await next(bloc, EnrollmentPinConfirmed("12345"));
    expect(bio, isA<EnrollmentBiometric>());
    expect((bio as EnrollmentBiometric).step.number, 2);

    final email = await next(bloc, EnrollmentBiometricDone());
    expect(email, isA<EnrollmentEmail>());
    expect((email as EnrollmentEmail).step.number, 3);
    expect(email.step.total, 3);
  });

  test("the account is made as soon as the PIN is confirmed, without an "
      "address", () async {
    final bloc = newBloc();
    await toAfterPin(bloc);

    expect(enrollments(), 1);
    final enroll = bridge.dispatched.whereType<EnrollEvent>().single;
    expect(enroll.email, "");
    expect(enroll.pin, "12345");
    expect(await bloc.account, isNull);
    expect(bloc.pin, "12345");
  });

  test("without biometrics the e-mail step is step 2 of 2", () async {
    final bloc = newBloc(biometric: false);
    final email = await toAfterPin(bloc);

    expect(email, isA<EnrollmentEmail>());
    expect((email as EnrollmentEmail).step.number, 2);
    expect(email.step.total, 2);
  });

  test("without the e-mail step Face ID is the last step", () async {
    final bloc = newBloc(email: false);
    final bio = await toAfterPin(bloc);
    expect((bio as EnrollmentBiometric).step.total, 2);

    bloc.add(EnrollmentBiometricDone());
    await expectLater(
      bloc.stream,
      emitsInOrder([isA<Enrolling>(), isA<EnrollmentCompleted>()]),
    );
  });

  test("with neither, the PIN has no step number and the app is set up "
      "straight after", () async {
    final bloc = newBloc(biometric: false, email: false);
    await next(bloc, EnrollmentTermsUpdated(isAccepted: true));
    final pin = await next(bloc, EnrollmentNextPressed());
    expect((pin as EnrollmentChoosePin).step, isNull);

    await next(bloc, EnrollmentPinChosen("12345"));
    bloc.add(EnrollmentPinConfirmed("12345"));
    await expectLater(
      bloc.stream,
      emitsInOrder([isA<Enrolling>(), isA<EnrollmentCompleted>()]),
    );
  });

  test(
    "skipping the e-mail step completes once the account is there",
    () async {
      final hold = holdEnrollment = Completer<void>();
      final bloc = newBloc(biometric: false);
      await toAfterPin(bloc);

      bloc.add(EnrollmentEmailDone());
      // Setting up shows while the account is still being made.
      expect(await bloc.stream.first, isA<Enrolling>());
      hold.complete();
      expect(await bloc.stream.first, isA<EnrollmentCompleted>());
      expect(enrollments(), 1);
    },
  );

  test("a failed account at the end can be retried", () async {
    enrollWorks = false;
    final bloc = newBloc(biometric: false);
    await toAfterPin(bloc);

    bloc.add(EnrollmentEmailDone());
    await expectLater(
      bloc.stream,
      emitsInOrder([isA<Enrolling>(), isA<EnrollmentFailed>()]),
    );

    enrollWorks = true;
    bloc.add(EnrollmentRetried());
    await expectLater(
      bloc.stream,
      emitsInOrder([isA<Enrolling>(), isA<EnrollmentCompleted>()]),
    );
    expect(enrollments(), 2);
  });

  test(
    "a failed account from the e-mail step returns there after a retry",
    () async {
      enrollWorks = false;
      final bloc = newBloc(biometric: false);
      await toAfterPin(bloc);
      final error = await bloc.account;
      expect(error, isNotNull);

      expect(
        await next(bloc, EnrollmentAccountFailed(error!)),
        isA<EnrollmentFailed>(),
      );
      enrollWorks = true;
      bloc.add(EnrollmentRetried());
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<Enrolling>(), isA<EnrollmentEmail>()]),
      );
    },
  );

  test("back from a failure starts over at the PIN", () async {
    enrollWorks = false;
    final bloc = newBloc(biometric: false, email: false);
    await next(bloc, EnrollmentTermsUpdated(isAccepted: true));
    await next(bloc, EnrollmentNextPressed());
    await next(bloc, EnrollmentPinChosen("12345"));
    bloc.add(EnrollmentPinConfirmed("12345"));
    await expectLater(
      bloc.stream,
      emitsInOrder([isA<Enrolling>(), isA<EnrollmentFailed>()]),
    );

    expect(
      await next(bloc, EnrollmentPreviousPressed()),
      isA<EnrollmentChoosePin>(),
    );
  });

  test(
    "a different second PIN chooses again, without making an account",
    () async {
      final bloc = newBloc();
      await next(bloc, EnrollmentTermsUpdated(isAccepted: true));
      await next(bloc, EnrollmentNextPressed());
      await next(bloc, EnrollmentPinChosen("12345"));
      // The confirm screen compares the PINs and reports the mismatch.
      final again = await next(bloc, EnrollmentPinMismatch());

      expect(again, isA<EnrollmentChoosePin>());
      expect(enrollments(), 0);
    },
  );

  test("a second Continue during the biometric check is ignored", () async {
    final check = Completer<bool>();
    final bloc = newBloc(biometricCheck: check.future);
    final states = <EnrollmentState>[];
    final sub = bloc.stream.listen(states.add);
    addTearDown(sub.cancel);
    await next(bloc, EnrollmentTermsUpdated(isAccepted: true));
    bloc.add(EnrollmentNextPressed());
    bloc.add(EnrollmentNextPressed());
    await Future<void>.delayed(Duration.zero);
    check.complete(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state, isA<EnrollmentChoosePin>());
    expect(states.whereType<EnrollmentChoosePin>().length, 1);
  });

  test(
    "terms toggled during the biometric check: still the PIN step",
    () async {
      final check = Completer<bool>();
      final bloc = newBloc(biometricCheck: check.future);
      await next(bloc, EnrollmentTermsUpdated(isAccepted: true));
      bloc.add(EnrollmentNextPressed());
      bloc.add(EnrollmentTermsUpdated(isAccepted: false));
      await Future<void>.delayed(Duration.zero);
      check.complete(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, isA<EnrollmentChoosePin>());
    },
  );
}
