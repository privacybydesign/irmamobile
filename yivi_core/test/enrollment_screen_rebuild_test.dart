import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/providers/email_linking_provider.dart";
import "package:yivi_core/src/screens/enrollment/enrollment_screen.dart";
import "package:yivi_core/src/screens/pin/providers/biometric_provider.dart";

import "support/onboarding_v2_harness.dart";

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  late RecordingBridge bridge;
  late IrmaRepository repo;

  setUp(() async {
    bridge = RecordingBridge()
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

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final digit in pin.split("")) {
      await tester.tap(find.byKey(Key("number_pad_key_$digit")));
      await tester.pump(const Duration(milliseconds: 60));
    }
    await settle(tester);
  }

  testWidgets("the chosen PIN survives a rebuild before it is confirmed", (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    var dark = false;
    late StateSetter setOuter;
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
          builder: (context, state) => StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return Theme(
                data: dark ? ThemeData.dark() : ThemeData.light(),
                child: EnrollmentScreen(),
              );
            },
          ),
        ),
        GoRoute(path: "/home", builder: (context, state) => const SizedBox()),
      ],
    );
    await settle(tester);

    final start = find.byKey(const Key("enrollment_next_button"));
    await tester.ensureVisible(start);
    await settle(tester);
    await tester.tap(start);
    await settle(tester);
    await tester.tap(find.byKey(const Key("enrollment_terms_continue")));
    await settle(tester);
    await tester.tap(find.byKey(const Key("error_reports_dont_share")));
    await settle(tester);

    await typePin(tester, "86315");
    expect(bridge.dispatched.whereType<EnrollEvent>(), isEmpty);

    // Something above the screen changes (here: the system switches to dark
    // mode) while the confirm step shows.
    setOuter(() => dark = true);
    await settle(tester);

    await typePin(tester, "86315");
    expect(find.byKey(const Key("pin_again_error")), findsNothing);
    // The seal, then the done page: Continue goes into the app.
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(bridge.dispatched.whereType<EnrollEvent>(), hasLength(1));
    await tester.tap(find.byKey(const Key("enrollment_continue")));
    await settle(tester);
    expect(currentLocation(router), "/home");
  });
}
