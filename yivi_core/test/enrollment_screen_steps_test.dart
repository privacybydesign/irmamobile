import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/providers/email_linking_provider.dart";
import "package:yivi_core/src/screens/enrollment/done/enrollment_done_page.dart";
import "package:yivi_core/src/screens/enrollment/enrollment_screen.dart";
import "package:yivi_core/src/screens/enrollment/error_reports/enrollment_error_reports_screen.dart";
import "package:yivi_core/src/screens/enrollment/pin/enrollment_pin_page.dart";
import "package:yivi_core/src/screens/enrollment/terms/enrollment_terms_screen.dart";
import "package:yivi_core/src/screens/enrollment/welcome/welcome_screen.dart";
import "package:yivi_core/src/screens/enrollment/widgets/enrollment_actions.dart";
import "package:yivi_core/src/screens/pin/pin_entry.dart";
import "package:yivi_core/src/screens/pin/providers/biometric_provider.dart";
import "package:yivi_core/src/widgets/sheet/sheet.dart";

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
  final accept = find.byKey(const Key("enrollment_terms_continue"));
  final share = find.byKey(const Key("error_reports_share"));
  final dontShare = find.byKey(const Key("error_reports_dont_share"));
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
    expect(label(tester), "Step 1 of 4");

    // Back from the terms: the welcome page again, without the bar, and
    // the cards and the rest back in place. Twice: it goes again.
    double shown() => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.text("Your digital identity, safe on your phone"),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;
    for (var round = 0; round < 2; round++) {
      await tester.tap(barBack);
      await settle(tester);
      expect(find.byType(EnrollmentTermsScreen), findsNothing);
      expect(label(tester), "");
      expect(shown(), 1);
      expect(start, findsOneWidget);
      if (round == 0) await tapVisible(tester, start);
    }

    await tapVisible(tester, start);
    await tapVisible(tester, accept);
    expect(find.byType(EnrollmentErrorReportsScreen), findsOneWidget);
    expect(label(tester), "Step 2 of 4");

    await tapVisible(tester, dontShare);
    expect(find.byType(EnrollmentPinPage), findsOneWidget);
    expect(label(tester), "Step 3 of 4");

    await tester.tap(barBack);
    await settle(tester);
    expect(find.byType(EnrollmentErrorReportsScreen), findsOneWidget);
    expect(label(tester), "Step 2 of 4");
  });

  testWidgets("accepting records the terms, the answer the reports", (
    tester,
  ) async {
    await pumpEnrollment(tester);
    await tapVisible(tester, start);
    await tapVisible(tester, accept);
    expect(repo.preferences.acceptedTermsUrl, isNotNull);
    await tapVisible(tester, share);
    expect(
      await tester.runAsync(() => repo.preferences.reportErrors.stream.first),
      isTrue,
    );
  });

  testWidgets("the buttons stay over the pages: the red one narrows into "
      "Share reports", (tester) async {
    await pumpEnrollment(tester);
    await tapVisible(tester, start);
    expect(find.byType(EnrollmentActionsLayer), findsOneWidget);
    final full = tester.getSize(accept).width;
    final bottom = tester.getRect(accept).bottom;

    await tester.tap(accept);
    await settle(tester);
    expect(tester.getSize(share).width, lessThan(full * 0.6));
    expect(tester.getRect(share).bottom, bottom);
    expect(
      tester.getCenter(dontShare).dx,
      lessThan(tester.getCenter(share).dx),
    );
    // Once: the pages only keep their room.
    expect(share, findsOneWidget);
  });

  testWidgets("a step comes in on a shared axis, over the one before", (
    tester,
  ) async {
    await pumpEnrollment(tester);
    await tapVisible(tester, start);
    await tester.ensureVisible(accept);
    await settle(tester);

    await tester.tap(accept);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    // Mid-change: both pages are there, the bar once.
    expect(find.byType(EnrollmentErrorReportsScreen), findsOneWidget);
    expect(find.byType(EnrollmentTermsScreen), findsOneWidget);
    expect(find.byKey(const Key("enrollment_bar")), findsOneWidget);
    await settle(tester);
    expect(
      find.byType(EnrollmentTermsScreen, skipOffstage: true),
      findsNothing,
    );
  });

  testWidgets("the system back button goes back a step", (tester) async {
    await pumpEnrollment(tester);
    await tapVisible(tester, start);
    await tapVisible(tester, accept);
    await tapVisible(tester, dontShare);
    expect(find.byType(EnrollmentPinPage), findsOneWidget);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(EnrollmentPinPage), findsNothing);
    expect(label(tester), "Step 2 of 4");
  });

  testWidgets("a sheet goes over the bar and the buttons", (tester) async {
    await pumpEnrollment(tester);
    await tapVisible(tester, start);
    await tester.tap(find.byKey(const Key("enrollment_terms_open")));
    await settle(tester);
    final sheet = find.byKey(const Key("legal_sheet_terms"));
    expect(sheet, findsOneWidget);
    // On the root navigator, not the steps' own under the bar.
    expect(
      find.ancestor(of: sheet, matching: find.byType(SheetsOverEverything)),
      findsNothing,
    );
  });

  testWidgets("Help improve Yivi?: the icon and the text in the middle", (
    tester,
  ) async {
    await pumpEnrollment(tester);
    await tapVisible(tester, start);
    await tapVisible(tester, accept);
    final top = tester.getRect(find.byKey(const Key("enrollment_bar"))).bottom;
    final bottom = tester.getRect(share).top;
    final group = tester
        .getRect(find.byIcon(Icons.bug_report_outlined))
        .expandToInclude(
          tester.getRect(find.text("You can change this later in Settings.")),
        );
    expect(group.center.dy, closeTo((top + bottom) / 2, 24));
  });

  testWidgets("the PIN goes into the lock: setting up, then done, and "
      "Continue goes into the app", (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final router = await pumpRoutes(
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
    await tapVisible(tester, start);
    await tapVisible(tester, accept);
    await tapVisible(tester, dontShare);
    Future<void> type(String pin) async {
      for (final d in pin.split("")) {
        await tester.tap(find.byKey(Key("number_pad_key_$d")));
        await tester.pump(const Duration(milliseconds: 60));
      }
    }

    await type("58193");
    await settle(tester);
    await type("58193");
    // Matched: green for a moment, then the done page, setting up.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(EnrollmentDonePage), findsNothing);
    await tester.pump(pinSealPause);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(EnrollmentDonePage), findsOneWidget);
    expect(find.text("Setting up your app"), findsOneWidget);
    expect(find.byKey(const Key("enrollment_continue")), findsNothing);

    // The account is there: done, then Continue.
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text("You’re all set"), findsOneWidget);
    expect(currentLocation(router), "/enrollment");
    await tester.tap(find.byKey(const Key("enrollment_continue")));
    await settle(tester);
    expect(currentLocation(router), "/home");
  });
}
