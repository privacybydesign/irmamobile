// Where the app sends the user: the router's redirect, the loading screen,
// the lock overlay and the routes that take arguments, in the whole app over
// a fake bridge.
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/error_event.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/screens/activity/activity_detail_screen.dart";
import "package:yivi_core/src/screens/data/credential_detail/credential_detail_screen.dart";
import "package:yivi_core/src/screens/enrollment/enrollment_screen.dart";
import "package:yivi_core/src/screens/error/error_screen.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/loading/loading_screen.dart";
import "package:yivi_core/src/screens/name_changed/name_changed_screen.dart";
import "package:yivi_core/src/screens/pin/pin_screen.dart";
import "package:yivi_core/src/screens/required_update/required_update_screen.dart";
import "package:yivi_core/src/screens/reset_pin/reset_pin_screen.dart";
import "package:yivi_core/src/screens/rooted_warning/rooted_warning_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";

import "support/app_harness.dart";

final _log = LogInfo(
  id: "log-1",
  type: LogType.disclosure,
  time: DateTime.utc(2026, 10, 1),
  issuanceLog: null,
  disclosureLog: DisclosureLog(
    protocol: Protocol.irma,
    credentials: const [],
    verifier: TrustedParty(
      id: "shop",
      name: "Webshop",
      url: null,
      parent: null,
      verified: true,
    ),
  ),
  signedMessageLog: null,
  removalLog: null,
);

void main() {
  late AppHarness app;

  setUp(() async {
    app = await AppHarness.create();
    // Each test that wants the notice turns it on.
    await app.repo.preferences.showNameChangedNotification.set(false);
  });

  testWidgets("19. until every input is known nothing redirects", (
    tester,
  ) async {
    await app.repo.preferences.showNameChangedNotification.set(true);
    await app.pump(tester);
    // The enrollment status alone: the loading screen goes home, and the
    // notice waits for the version, which follows from the scheme rules.
    app.enrolled();
    await app.run(tester);

    expect(app.location, "/home");
    expect(find.byType(NameChangedScreen), findsNothing);

    app.schemes();
    await app.run(tester);

    expect(app.location, "/name_changed");
    await app.unmount(tester);
  });

  testWidgets("19. before the enrollment status the app stays on loading", (
    tester,
  ) async {
    await app.pump(tester);
    app.schemes();
    await app.run(tester);

    expect(app.location, "/loading");
    expect(find.byType(LoadingScreen), findsOneWidget);
    await app.unmount(tester);
  });

  group("20. the enrollment status", () {
    testWidgets("unenrolled goes to the enrollment", (tester) async {
      await app.pump(tester);
      app.unenrolled();
      app.schemes();
      await app.run(tester);

      expect(app.location, "/enrollment");
      expect(find.byType(EnrollmentScreen), findsOneWidget);
      await app.unmount(tester);
    });

    testWidgets("enrolled goes home, without a transition", (tester) async {
      await app.pump(tester);
      app.enrolled();
      app.schemes();
      await app.run(tester);

      expect(app.location, "/home");
      final route = ModalRoute.of(
        tester.element(find.byType(HomeScreen, skipOffstage: false)),
      )!;
      expect(route, isA<PageRouteBuilder<void>>());
      expect(route.transitionDuration, Duration.zero);
      await app.unmount(tester);
    });
  });

  group("21. redirects", () {
    testWidgets("a rooted device goes to the warning before anything "
        "else", (tester) async {
      await app.repo.preferences.showNameChangedNotification.set(true);
      await app.pump(tester, rooted: true);
      app.unenrolled();
      app.schemes(minimumBuild: 101);
      await app.run(tester);

      expect(app.location, "/rooted_warning");
      expect(find.byType(RootedWarningScreen), findsOneWidget);
      await app.unmount(tester);
    });

    testWidgets("the name change notice", (tester) async {
      await app.repo.preferences.showNameChangedNotification.set(true);
      await app.pump(tester);
      app.enrolled();
      app.schemes(minimumBuild: 101);
      await app.run(tester);

      expect(app.location, "/name_changed");
      expect(find.byType(NameChangedScreen), findsOneWidget);
      await app.unmount(tester);
    });

    testWidgets("an update the schemes require", (tester) async {
      await app.pump(tester);
      app.enrolled();
      app.schemes(minimumBuild: 101);
      await app.run(tester);

      expect(app.location, "/update_required");
      expect(find.byType(RequiredUpdateScreen), findsOneWidget);
      await app.unmount(tester);
    });
  });

  group("22. the lock overlay", () {
    testWidgets("over home while locked", (tester) async {
      await app.pump(tester);
      app.enrolled();
      app.schemes();
      await app.run(tester);

      expect(app.location, "/home");
      expect(find.byType(PinScreen), findsOneWidget);

      app.repo.appLock.unlockLocally();
      await app.run(tester);
      expect(find.byType(PinScreen), findsNothing);
      await app.unmount(tester);
    });

    testWidgets("not over the enrollment", (tester) async {
      await app.pump(tester);
      app.unenrolled();
      app.schemes();
      await app.run(tester);
      app.repo.appLock.lock();
      await app.run(tester);

      expect(app.location, "/enrollment");
      expect(find.byType(PinScreen), findsNothing);
      await app.unmount(tester);
    });

    testWidgets("not over the error screen", (tester) async {
      await app.pump(tester);
      app.enrolled();
      app.schemes();
      await app.run(tester);
      app.router.go("/error", extra: "broken");
      await app.run(tester);

      expect(find.byType(ErrorScreen), findsOneWidget);
      expect(find.byType(PinScreen), findsNothing);
      await app.unmount(tester);
    });

    testWidgets("but over an error screen pushed on home: the router's "
        "location stays home", (tester) async {
      await app.pump(tester);
      app.enrolled();
      app.schemes();
      await app.run(tester);
      app.router.push("/error", extra: "broken");
      await app.run(tester);

      expect(app.location, "/home");
      expect(find.byType(PinScreen), findsOneWidget);
      await app.unmount(tester);
    });

    testWidgets("forgot PIN with the logged-out toast up: the toast does "
        "not follow onto the reset screen", (tester) async {
      await app.repo.preferences.acceptedLatestTerms.set(true);
      await app.pump(tester);
      // Logged out before the lock screen first shows, so it says so.
      app.repo.appLock.logOut();
      app.enrolled();
      app.schemes();
      await app.run(tester);
      expect(find.text("You have been logged out"), findsOneWidget);

      await tester.tap(find.text("I forgot my PIN"));
      // Through the push; a toast placed for the PIN screen would sit off
      // the reset screen, above its action bar.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(ResetPinScreen), findsOneWidget);
      expect(find.text("You have been logged out"), findsNothing);
      await app.unmount(tester);
    });
  });

  testWidgets("23. a fatal error while loading shows the error screen", (
    tester,
  ) async {
    await app.pump(tester);
    app.bridge.deliver(ErrorEvent(exception: "broken", stack: "", fatal: true));
    await app.run(tester);

    expect(app.location, "/loading");
    expect(find.byType(ErrorScreen), findsOneWidget);
    await app.unmount(tester);
  });

  group("24. routes with arguments", () {
    Future<void> home(WidgetTester tester) async {
      await app.pump(tester);
      app.enrolled();
      app.schemes();
      await app.run(tester);
      app.repo.appLock.unlockLocally();
      await app.run(tester);
    }

    testWidgets("a card, by hash and the field it was found by", (
      tester,
    ) async {
      await home(tester);
      app.router.push("/home/credential?hash=h-1&found=email");
      await app.run(tester);

      final screen = tester.widget<CredentialDetailScreen>(
        find.byType(CredentialDetailScreen),
      );
      expect(screen.hash, "h-1");
      expect(screen.found, "email");
      await app.unmount(tester);
    });

    testWidgets("an activity entry", (tester) async {
      await home(tester);
      app.router.push("/home/activity_details", extra: _log);
      await app.run(tester);

      final screen = tester.widget<ActivityDetailsScreen>(
        find.byType(ActivityDetailsScreen),
      );
      expect(screen.logEntry, same(_log));
      await app.unmount(tester);
    });

    testWidgets("an error, with its message", (tester) async {
      await home(tester);
      app.router.push("/error", extra: "the message");
      await app.run(tester);

      final screen = tester.widget<ErrorScreen>(find.byType(ErrorScreen));
      expect(screen.details, "the message");
      await app.unmount(tester);
    });

    testWidgets("a session, by id and whether one waits under it", (
      tester,
    ) async {
      await home(tester);
      app.router.push("/session?session_id=3&has_underlying_session=true");
      await app.run(tester);

      final screen = tester.widget<SessionScreen>(find.byType(SessionScreen));
      expect(screen.sessionId, 3);
      expect(screen.hasUnderlyingSession, isTrue);
      await app.unmount(tester);
    });
  });
}
