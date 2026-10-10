import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/screens/enrollment/bloc/enrollment_bloc.dart";
import "package:yivi_core/src/screens/enrollment/enrollment_screen.dart";
import "package:yivi_core/src/screens/enrollment/introduction/introduction_screen.dart";

import "support/onboarding_v2_harness.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IrmaPreferences prefs;
  late RecordingBridge bridge;
  late IrmaRepository repo;

  setUp(() async {
    prefs = await freshPreferences();
    bridge = RecordingBridge();
    repo = IrmaRepository(client: bridge, preferences: prefs);
  });

  tearDown(() => repo.close());

  group("completing onboarding", () {
    // The bridge confirms the enrollment, as the Go side does.
    setUp(() {
      bridge.respond = (event) => event is EnrollEvent
          ? EnrollmentSuccessEvent(schemeManagerID: "pbdf")
          : null;
    });

    Future<GoRouter> pumpEnrollment(WidgetTester tester) => pumpRoutes(
      tester,
      repo: repo,
      initialLocation: "/enrollment",
      routes: [
        GoRoute(path: "/enrollment", builder: (_, _) => EnrollmentScreen()),
        GoRoute(path: "/home", builder: (_, _) => const Text("home screen")),
        GoRoute(
          path: "/back_to_website",
          builder: (_, _) => const Text("back to website screen"),
        ),
      ],
    );

    Future<void> finishOnboarding(
      WidgetTester tester, {
      required int introductionPages,
    }) async {
      final bloc = BlocProvider.of<EnrollmentBloc>(
        tester.element(find.byType(IntroductionScreen)),
      );
      final events = <EnrollmentBlocEvent>[
        for (var i = 0; i < introductionPages; i++) EnrollmentNextPressed(),
        EnrollmentTermsUpdated(isAccepted: true),
        EnrollmentNextPressed(),
        EnrollmentPinChosen("12345"),
        EnrollmentPinConfirmed("12345"),
        EnrollmentEmailSkipped(),
      ];
      for (final event in events) {
        bloc.add(event);
        await settle(tester);
      }
      // Completing writes a marker to the preference store and reads another,
      // which takes turns on the real and the fake clock.
      for (var i = 0; i < 5; i++) {
        await settle(tester);
      }
    }

    testWidgets("flag off: goes home and sets no marker", (tester) async {
      final router = await pumpEnrollment(tester);

      await finishOnboarding(tester, introductionPages: 3);

      expect(currentLocation(router), "/home");
      expect(
        await tester.runAsync(() => prefs.getReadyChipPending().first),
        isFalse,
      );
    });

    testWidgets("flag on: goes home and marks the ready chip", (tester) async {
      await enableOnboardingV2(prefs);
      final router = await pumpEnrollment(tester);

      await finishOnboarding(tester, introductionPages: 1);

      expect(currentLocation(router), "/home");
      expect(
        await tester.runAsync(() => prefs.getReadyChipPending().first),
        isTrue,
      );
    });

    testWidgets("flag on, opened from a website: shows the way back", (
      tester,
    ) async {
      await enableOnboardingV2(prefs);
      await prefs.markBackToWebsitePending();
      final router = await pumpEnrollment(tester);

      await finishOnboarding(tester, introductionPages: 1);

      expect(currentLocation(router), "/back_to_website");
    });
  });
}
