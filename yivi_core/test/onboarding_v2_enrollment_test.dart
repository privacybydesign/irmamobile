import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/enrollment/bloc/enrollment_bloc.dart";
import "package:yivi_core/src/screens/enrollment/introduction/introduction_screen.dart";
import "package:yivi_core/src/screens/enrollment/introduction/models/introduction_entry.dart";
import "package:yivi_core/src/screens/enrollment/introduction/widgets/introduction_animation_wrapper.dart";
import "package:yivi_core/src/screens/enrollment/widgets/enrollment_layout.dart";
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

    group("page of the design", () {
      const title = "Yivi is an app for your digital identity";
      final next = find.byKey(const Key("enrollment_next_button"));
      final hero = findSvg("enrollment/introduction_1.svg");

      Future<void> pumpPage(WidgetTester tester, {Size? size}) async {
        usePhoneScreen(tester, size: size ?? const Size(390, 844));
        await pumpIntro(tester, entry: IntroductionEntry.returning);
      }

      testWidgets("flag on: a 300 px picture 48 px from the top", (
        tester,
      ) async {
        await enableOnboardingV2(prefs);
        await pumpPage(tester);

        expect(tester.getRect(hero), const Rect.fromLTWH(45, 48, 300, 300));
        expect(find.byType(EnrollmentLayout), findsNothing);
      });

      testWidgets("flag on: the title 32 px below, the text 12 px below that", (
        tester,
      ) async {
        await enableOnboardingV2(prefs);
        await pumpPage(tester);

        final titleRect = tester.getRect(find.text(title));
        expect(titleRect.left, 24);
        expect(titleRect.top, 48 + 300 + 32);
        final style = tester.widget<Text>(find.text(title)).style!;
        expect(style.fontSize, 26);
        expect(style.fontWeight, FontWeight.w700);
        expect(style.height, 36 / 26);
        expect(
          tester.getTopLeft(find.textContaining("Your official name")).dy,
          titleRect.bottom + 12,
        );
      });

      testWidgets("flag on: the text ends with a full stop", (tester) async {
        await enableOnboardingV2(prefs);
        await pumpPage(tester);

        expect(
          find.text(
            "Your official name, birthdate, address, social security number and more. Safely stored in your Yivi-app.",
          ),
          findsOneWidget,
        );
      });

      testWidgets("flag on: a 160 px wide, 48 px high button at the right", (
        tester,
      ) async {
        await enableOnboardingV2(prefs);
        await pumpPage(tester);

        expect(tester.getRect(next), const Rect.fromLTWH(206, 764, 160, 48));
        expect(
          find.byKey(const Key("enrollment_previous_button")),
          findsNothing,
        );
      });

      testWidgets("flag on: scrolls on a small screen instead of overflowing", (
        tester,
      ) async {
        await enableOnboardingV2(prefs);
        await pumpPage(tester, size: const Size(320, 480));
        final text = find.textContaining("Your official name");
        expect(tester.getTopLeft(text).dy, greaterThan(480 - 96));

        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -300),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(tester.getTopLeft(text).dy, lessThan(480 - 96));
        expect(tester.getRect(next).bottom, 480 - 32);
      });

      testWidgets("flag on: landscape keeps the hero beside the text", (
        tester,
      ) async {
        await enableOnboardingV2(prefs);
        await pumpPage(tester, size: const Size(844, 390));

        expect(find.byType(EnrollmentLayout), findsOneWidget);
        expect(find.byType(YiviProgressIndicator), findsNothing);
        expect(tester.getSize(next).height, 48);
      });

      testWidgets("flag off: the hero fills the top half, buttons are 50 px", (
        tester,
      ) async {
        await pumpPage(tester);

        expect(find.byType(EnrollmentLayout), findsOneWidget);
        expect(tester.getSize(hero).height, greaterThan(300));
        expect(tester.getSize(next).height, 50);
      });
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
