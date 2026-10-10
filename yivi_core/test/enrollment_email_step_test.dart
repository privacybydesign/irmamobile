import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/screens/enrollment/bloc/enrollment_bloc.dart";
import "package:yivi_core/src/screens/enrollment/introduction/introduction_screen.dart";

/// Answers every enrollment the way the Go core would, after the repository
/// has started waiting for it.
class _EnrollingBridge extends IrmaBridge {
  final enrollEvents = <EnrollEvent>[];
  var fail = false;

  @override
  void dispatch(Event event) {
    if (event is! EnrollEvent) return;
    enrollEvents.add(event);
    Future<void>.delayed(Duration.zero, () {
      addEvent(
        fail
            ? EnrollmentFailureEvent(
                schemeManagerID: "pbdf",
                error: SessionError(errorType: "unknown", info: ""),
              )
            : EnrollmentSuccessEvent(schemeManagerID: "pbdf"),
      );
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pin = "12345";

  late IrmaPreferences prefs;
  late _EnrollingBridge bridge;
  late EnrollmentBloc bloc;
  late List<EnrollmentState> states;

  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  setUp(() async {
    prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await prefs.clearAll();
    bridge = _EnrollingBridge();
    bloc = EnrollmentBloc(
      language: "en",
      repo: IrmaRepository(client: bridge, preferences: prefs),
    );
    states = [];
    final subscription = bloc.stream.listen(states.add);
    addTearDown(() async {
      await subscription.cancel();
      await bloc.close();
    });
  });

  Future<void> add(EnrollmentBlocEvent event) async {
    bloc.add(event);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  Future<void> upToConfirmedPin() async {
    for (var i = 0; i < IntroductionScreen.introductionSteps.length; i++) {
      await add(EnrollmentNextPressed());
    }
    await add(EnrollmentTermsUpdated(isAccepted: true));
    await add(EnrollmentNextPressed());
    await add(EnrollmentPinChosen(pin));
    await add(EnrollmentPinConfirmed(pin));
  }

  test("asks for an e-mail address after the PIN with the flag off", () async {
    await upToConfirmedPin();

    expect(states.last, isA<EnrollmentProvideEmail>());
    expect(bridge.enrollEvents, isEmpty);
  });

  test(
    "enrolls right after the PIN, without an e-mail, with the flag on",
    () async {
      await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);

      await upToConfirmedPin();

      expect(states.whereType<EnrollmentProvideEmail>(), isEmpty);
      expect(states.whereType<EnrollmentEmailSent>(), isEmpty);
      expect(states.whereType<Enrolling>(), hasLength(1));
      expect(states.last, isA<EnrollmentCompleted>());
      expect(bridge.enrollEvents.single.email, "");
      expect(bridge.enrollEvents.single.pin, pin);
    },
  );

  test(
    "going back from a failed enrollment returns to the PIN with the flag on",
    () async {
      await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);
      bridge.fail = true;

      await upToConfirmedPin();
      expect(states.last, isA<EnrollmentFailed>());

      await add(EnrollmentPreviousPressed());
      expect(states.last, isA<EnrollmentChoosePin>());
    },
  );

  test(
    "going back from a failed enrollment returns to the e-mail step with the flag off",
    () async {
      bridge.fail = true;

      await upToConfirmedPin();
      await add(EnrollmentEmailProvided("jan@example.com"));
      expect(states.last, isA<EnrollmentFailed>());

      await add(EnrollmentPreviousPressed());
      final state = states.last;
      expect(state, isA<EnrollmentProvideEmail>());
      expect((state as EnrollmentProvideEmail).email, "jan@example.com");
    },
  );
}
