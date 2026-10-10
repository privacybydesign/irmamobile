import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/enrollment/bloc/enrollment_bloc.dart";
import "package:yivi_core/src/screens/enrollment/introduction/introduction_screen.dart";
import "package:yivi_core/src/screens/enrollment/introduction/models/introduction_entry.dart";
import "package:yivi_core/src/screens/enrollment/introduction/widgets/introduction_animation_wrapper.dart";
import "package:yivi_core/src/widgets/yivi_progress_indicator.dart";

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

  group("EnrollmentBloc introduction", () {
    late EnrollmentBloc bloc;

    setUp(() => bloc = EnrollmentBloc(language: "en", repo: repo));

    tearDown(() => bloc.close());

    Future<EnrollmentState> send(EnrollmentBlocEvent event) {
      final next = bloc.stream.first;
      bloc.add(event);
      return next;
    }

    test(
      "flag off: three steps, back from the terms lands on the last",
      () async {
        var state = await send(EnrollmentNextPressed());
        expect((state as EnrollmentIntroduction).currentStepIndex, 1);

        state = await send(EnrollmentNextPressed());
        expect((state as EnrollmentIntroduction).currentStepIndex, 2);

        expect(
          await send(EnrollmentNextPressed()),
          isA<EnrollmentAcceptTerms>(),
        );

        state = await send(EnrollmentPreviousPressed());
        expect((state as EnrollmentIntroduction).currentStepIndex, 2);
        expect(state.entry, IntroductionEntry.returning);
      },
    );

    test("flag on: one step, then the terms", () async {
      await enableOnboardingV2(prefs);

      expect(await send(EnrollmentNextPressed()), isA<EnrollmentAcceptTerms>());
    });

    test("flag on: back from the terms lands on the only step", () async {
      await enableOnboardingV2(prefs);
      await send(EnrollmentNextPressed());

      final state = await send(EnrollmentPreviousPressed());

      expect((state as EnrollmentIntroduction).currentStepIndex, 0);
      expect(state.entry, IntroductionEntry.returning);
    });
  });

  group("IntroductionScreen", () {
    Future<void> pumpIntro(
      WidgetTester tester, {
      IntroductionEntry entry = IntroductionEntry.first,
    }) async {
      await pumpHome(
        tester,
        repo: repo,
        home: IntroductionScreen(
          currentStepIndex: 0,
          entry: entry,
          onContinue: () {},
          onPrevious: () {},
        ),
      );
      await settle(tester);
    }

    // The animation wrapper holds a timer until it is disposed.
    Future<void> unmount(WidgetTester tester) =>
        tester.pumpWidget(const SizedBox());

    testWidgets("flag off: shows the step progress dots", (tester) async {
      await pumpIntro(tester);

      expect(find.byType(YiviProgressIndicator), findsOneWidget);
      await unmount(tester);
    });

    testWidgets("flag on: the single page has no progress dots", (
      tester,
    ) async {
      await enableOnboardingV2(prefs);
      await pumpIntro(tester);

      expect(find.byType(YiviProgressIndicator), findsNothing);
      expect(
        find.text("Yivi is an app for your digital identity"),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets("plays the intro animation on first entry", (tester) async {
      await pumpIntro(tester);

      expect(find.byType(IntroductionAnimationWrapper), findsOneWidget);
      await unmount(tester);
    });

    testWidgets("skips the intro animation when coming back", (tester) async {
      await pumpIntro(tester, entry: IntroductionEntry.returning);

      expect(find.byType(IntroductionAnimationWrapper), findsNothing);
    });
  });
}
