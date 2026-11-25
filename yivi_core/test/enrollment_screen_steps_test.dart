import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/providers/email_linking_provider.dart";
import "package:yivi_core/src/screens/enrollment/choose_pin/choose_pin_screen.dart";
import "package:yivi_core/src/screens/enrollment/enrollment_screen.dart";
import "package:yivi_core/src/screens/enrollment/terms/enrollment_terms_screen.dart";
import "package:yivi_core/src/screens/enrollment/welcome/welcome_screen.dart";
import "package:yivi_core/src/screens/pin/providers/biometric_provider.dart";
import "package:yivi_core/src/widgets/buttons/pill_buttons.dart";

import "support/onboarding_v2_harness.dart";

/// The steps as pages: pushed over each other under one bar that stays,
/// with back (the bar's button, or the system's) popping a step.
void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  late IrmaRepository repo;

  setUp(() async {
    final bridge = RecordingBridge()
      ..respond = (event) => event is EnrollEvent
          ? EnrollmentSuccessEvent(schemeManagerID: event.schemeId)
          : null;
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpEnrollment(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await pumpRoutes(
      tester,
      repo: repo,
      initialLocation: "/enrollment",
      overrides: [
        biometricAvailableProvider.overrideWith((ref) async => false),
        emailLinkingOfferedProvider.overrideWithValue(false),
      ],
      routes: [
        GoRoute(
          path: "/enrollment",
          builder: (context, state) => EnrollmentScreen(),
        ),
        GoRoute(path: "/home", builder: (context, state) => const SizedBox()),
      ],
    );
    await settle(tester);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await settle(tester);
    await tester.tap(finder);
    await settle(tester);
  }

  final start = find.byKey(const Key("enrollment_next_button"));
  final accept = find.byKey(const Key("accept_terms_checkbox"));
  final next = find.byKey(const Key("enrollment_terms_continue"));
  final barBack = find.descendant(
    of: find.byKey(const Key("enrollment_bar")),
    matching: find.byKey(const Key("irma_app_bar_leading")),
  );
  String label(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key("enrollment_step_label"))).data!;

  testWidgets("the bar counts the steps and goes back a step", (tester) async {
    await pumpEnrollment(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(label(tester), "");

    await tapVisible(tester, start);
    expect(find.text("Before you start"), findsOneWidget);
    expect(label(tester), "Step 1 of 3");

    // Back from the terms: the welcome page again, without the bar, and
    // the cards and the rest back in place. Twice: it goes again.
    double shown() => tester
        .widget<Opacity>(
          find.ancestor(of: start, matching: find.byType(Opacity)).first,
        )
        .opacity;
    for (var round = 0; round < 2; round++) {
      await tester.tap(barBack);
      await settle(tester);
      expect(find.byType(EnrollmentTermsScreen), findsNothing);
      expect(label(tester), "");
      expect(shown(), 1);
      if (round == 0) await tapVisible(tester, start);
    }

    await tapVisible(tester, start);
    await tapVisible(tester, accept);
    await tapVisible(tester, next);
    expect(find.byType(ChoosePinScreen), findsOneWidget);
    expect(label(tester), "Step 2 of 3");
  });

  testWidgets("a step slides over the one before, which stays under it", (
    tester,
  ) async {
    await pumpEnrollment(tester);
    await tapVisible(tester, start);
    await tapVisible(tester, accept);
    await tester.ensureVisible(next);
    await settle(tester);

    await tester.tap(next);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    // Mid-push: both pages are there, the bar once.
    expect(find.byType(ChoosePinScreen), findsOneWidget);
    expect(find.byType(EnrollmentTermsScreen), findsOneWidget);
    expect(find.byKey(const Key("enrollment_bar")), findsOneWidget);
    await settle(tester);
  });

  testWidgets("the system back button goes back a step, the terms still "
      "accepted", (tester) async {
    await pumpEnrollment(tester);
    await tapVisible(tester, start);
    await tapVisible(tester, accept);
    await tapVisible(tester, next);
    expect(find.byType(ChoosePinScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(ChoosePinScreen), findsNothing);
    expect(label(tester), "Step 1 of 3");
    expect(tester.widget<PrimaryPillButton>(next).onPressed, isNotNull);
  });
}
