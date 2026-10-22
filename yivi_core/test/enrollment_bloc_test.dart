import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/screens/enrollment/bloc/enrollment_bloc.dart";

import "support/onboarding_v2_harness.dart";

SessionError _error() => SessionError(errorType: "transport", info: "offline");

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
      hold.future.then((_) => bridge.addEvent(reply));
      return null;
    };
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  EnrollmentBloc newBloc({bool biometric = true, bool email = true}) {
    final bloc = EnrollmentBloc(
      language: "en",
      repo: repo,
      biometricOffered: () async => biometric,
      emailOffered: () => email,
    );
    addTearDown(bloc.close);
    return bloc;
  }

  Future<EnrollmentState> next(EnrollmentBloc bloc, EnrollmentBlocEvent e) {
    final state = bloc.stream.first;
    bloc.add(e);
    return state;
  }

  /// Through the welcome page and both PIN pages.
  Future<EnrollmentState> toAfterPin(EnrollmentBloc bloc) async {
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
    "a different second PIN asks again, without making an account",
    () async {
      final bloc = newBloc();
      await next(bloc, EnrollmentTermsUpdated(isAccepted: true));
      await next(bloc, EnrollmentNextPressed());
      await next(bloc, EnrollmentPinChosen("12345"));
      final again = await next(bloc, EnrollmentPinConfirmed("54321"));

      expect(again, isA<EnrollmentConfirmPin>());
      expect((again as EnrollmentConfirmPin).confirmationFailed, isTrue);
      expect(enrollments(), 0);
    },
  );
}
