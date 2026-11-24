import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/screens/enrollment/bloc/enrollment_bloc.dart";
import "package:yivi_core/src/screens/enrollment/introduction/introduction_screen.dart";

class _NoopBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

class _FakeRepo extends IrmaRepository {
  _FakeRepo({required super.client, required super.preferences});

  final results = <EnrollmentEvent>[];
  final enrolledEmails = <String>[];

  @override
  Future<EnrollmentEvent> enroll({
    required String email,
    required String pin,
    required String language,
  }) async {
    enrolledEmails.add(email);
    return results.removeAt(0);
  }
}

EnrollmentFailureEvent _failure(SessionError error) =>
    EnrollmentFailureEvent(schemeManagerID: "pbdf", error: error);

EnrollmentFailureEvent _remoteFailure({
  required int status,
  required String message,
}) => _failure(
  SessionError(
    errorType: "api",
    info: "",
    remoteStatus: status,
    remoteError: RemoteError(
      status: status,
      errorName: "INVALID_REQUEST",
      message: message,
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRepo repo;
  late EnrollmentBloc bloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = _FakeRepo(
      client: _NoopBridge(),
      preferences: await IrmaPreferences.fromInstance(
        mostRecentTermsUrlNl: "",
        mostRecentTermsUrlEn: "",
      ),
    );
    bloc = EnrollmentBloc(language: "en", repo: repo);
  });

  tearDown(() async {
    await bloc.close();
    await repo.close();
  });

  /// Walks the bloc from the introduction to the email step.
  Future<void> toEmailStep() async {
    for (final _ in IntroductionScreen.introductionSteps) {
      bloc.add(EnrollmentNextPressed());
    }
    bloc.add(EnrollmentTermsUpdated(isAccepted: true));
    bloc.add(EnrollmentNextPressed());
    bloc.add(EnrollmentPinChosen("12345"));
    bloc.add(EnrollmentPinConfirmed("12345"));
    await pumpEventQueue();
    expect(bloc.state, isA<EnrollmentProvideEmail>());
  }

  group("enrollment email errors", () {
    test("the keyshare server rejecting the address returns to the email "
        "step with the address filled in", () async {
      repo.results.add(
        _remoteFailure(status: 400, message: "invalid email address"),
      );
      await toEmailStep();

      bloc.add(EnrollmentEmailProvided("jan@caeser.nl"));
      await pumpEventQueue();

      expect(
        bloc.state,
        isA<EnrollmentEmailRejected>().having(
          (s) => s.email,
          "email",
          "jan@caeser.nl",
        ),
      );
    });

    test("a corrected address can be submitted after a rejection", () async {
      repo.results
        ..add(_remoteFailure(status: 400, message: "invalid email address"))
        ..add(EnrollmentSuccessEvent(schemeManagerID: "pbdf"));
      await toEmailStep();
      bloc.add(EnrollmentEmailProvided("jan@caeser.nl"));
      await pumpEventQueue();

      bloc.add(EnrollmentEmailProvided("jan@caesar.nl"));
      await pumpEventQueue();

      expect(
        bloc.state,
        isA<EnrollmentEmailSent>().having(
          (s) => s.email,
          "email",
          "jan@caesar.nl",
        ),
      );
      expect(repo.enrolledEmails, ["jan@caeser.nl", "jan@caesar.nl"]);
    });

    test("the email step can be skipped after a rejection", () async {
      repo.results
        ..add(_remoteFailure(status: 400, message: "invalid email address"))
        ..add(EnrollmentSuccessEvent(schemeManagerID: "pbdf"));
      await toEmailStep();
      bloc.add(EnrollmentEmailProvided("jan@caeser.nl"));
      await pumpEventQueue();

      bloc.add(EnrollmentEmailSkipped());
      await pumpEventQueue();

      expect(bloc.state, isA<EnrollmentCompleted>());
      expect(repo.enrolledEmails, ["jan@caeser.nl", ""]);
    });

    test("back after a rejection goes to the PIN step", () async {
      repo.results.add(
        _remoteFailure(status: 400, message: "invalid email address"),
      );
      await toEmailStep();
      bloc.add(EnrollmentEmailProvided("jan@caeser.nl"));
      await pumpEventQueue();

      bloc.add(EnrollmentPreviousPressed());
      await pumpEventQueue();

      expect(bloc.state, isA<EnrollmentChoosePin>());
    });

    test("another 400 keeps the error screen", () async {
      repo.results.add(_remoteFailure(status: 400, message: "invalid pin"));
      await toEmailStep();

      bloc.add(EnrollmentEmailProvided("jan@caesar.nl"));
      await pumpEventQueue();

      expect(bloc.state, isA<EnrollmentFailed>());
    });

    test(
      "the same message with another status keeps the error screen",
      () async {
        repo.results.add(
          _remoteFailure(status: 500, message: "invalid email address"),
        );
        await toEmailStep();

        bloc.add(EnrollmentEmailProvided("jan@caesar.nl"));
        await pumpEventQueue();

        expect(bloc.state, isA<EnrollmentFailed>());
      },
    );

    test("an error without a server response keeps the error screen", () async {
      repo.results.add(
        _failure(SessionError(errorType: "transport", info: "")),
      );
      await toEmailStep();

      bloc.add(EnrollmentEmailProvided("jan@caesar.nl"));
      await pumpEventQueue();

      expect(bloc.state, isA<EnrollmentFailed>());
    });

    test("a failure without an address keeps the error screen", () async {
      repo.results.add(
        _remoteFailure(status: 400, message: "invalid email address"),
      );
      await toEmailStep();

      bloc.add(EnrollmentEmailSkipped());
      await pumpEventQueue();

      expect(bloc.state, isA<EnrollmentFailed>());
    });
  });
}
