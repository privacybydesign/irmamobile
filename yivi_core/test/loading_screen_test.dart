import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/models/error_event.dart";
import "package:yivi_core/src/screens/error/error_screen.dart";
import "package:yivi_core/src/screens/loading/loading_screen.dart";

import "support/onboarding_v2_harness.dart";

void main() {
  late RecordingBridge bridge;
  late IrmaRepository repo;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("irma.app/irma_mobile_bridge"),
          (_) async => null,
        );
    bridge = RecordingBridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  Future<GoRouter> pump(WidgetTester tester) => pumpRoutes(
    tester,
    repo: repo,
    initialLocation: "/",
    routes: [
      GoRoute(path: "/", builder: (context, state) => LoadingScreen()),
      GoRoute(path: "/home", builder: (context, state) => const Text("home")),
      GoRoute(
        path: "/enrollment",
        builder: (context, state) => const Text("enrollment"),
      ),
    ],
  );

  Future<void> status({required bool enrolled}) async => bridge.deliver(
    EnrollmentStatusEvent(
      enrolledSchemeManagerIds: enrolled ? ["pbdf"] : [],
      unenrolledSchemeManagerIds: enrolled ? [] : ["pbdf"],
    ),
  );

  Future<void> run(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await settle(tester);
    }
  }

  testWidgets("enrolled goes home", (tester) async {
    final router = await pump(tester);
    await status(enrolled: true);
    await run(tester);
    expect(currentLocation(router), "/home");
  });

  testWidgets("unenrolled goes to enrollment", (tester) async {
    final router = await pump(tester);
    await status(enrolled: false);
    await run(tester);
    expect(currentLocation(router), "/enrollment");
  });

  testWidgets("a fatal error shows the error screen", (tester) async {
    await pump(tester);
    bridge.deliver(ErrorEvent(exception: "broken", stack: "", fatal: true));
    await run(tester);
    expect(find.byType(ErrorScreen), findsOneWidget);
  });

  testWidgets(
    "15 s without a status reports a timeout",
    timeout: const Timeout(Duration(seconds: 40)),
    (tester) async {
      final router = await pump(tester);
      // The first frame is built on the real clock (pumpTranslated), and so
      // is the timer: wait for it for real.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 16)),
      );
      await run(tester);
      expect(currentLocation(router), "/");
      expect(find.byType(ErrorScreen), findsOneWidget);
    },
  );
}
