import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/authentication_events.dart";
import "package:yivi_core/src/models/change_pin_events.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/screens/change_pin/change_pin_screen.dart";

import "support/onboarding_v2_harness.dart";

/// Change PIN, step by step.
void main() {
  late RecordingBridge bridge;
  late IrmaRepository repo;

  /// The keyshare server's answers: a right old PIN is [right].
  const right = "24680";
  var left = 3;
  Event? changeAnswer;

  setUp(() async {
    left = 3;
    changeAnswer = ChangePinSuccessEvent();
    bridge = RecordingBridge()
      ..respond = (event) => switch (event) {
        AuthenticateEvent(:final pin) when pin == right =>
          AuthenticationSuccessEvent(),
        AuthenticateEvent() => AuthenticationFailedEvent(
          remainingAttempts: --left,
          blockedDuration: left == 0 ? 60 : 0,
        ),
        ChangePinEvent() => changeAnswer,
        _ => null,
      };
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
    await repo.preferences.longPin.set(false);
  });
  tearDown(() => repo.close());

  Future<GoRouter> pump(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final router = await pumpRoutes(
      tester,
      repo: repo,
      initialLocation: "/change_pin",
      routes: [
        GoRoute(
          path: "/home",
          builder: (_, _) => const Scaffold(body: Text("HOME")),
          routes: [
            GoRoute(
              path: "settings",
              builder: (_, _) => const Scaffold(body: Text("SETTINGS")),
            ),
          ],
        ),
        GoRoute(
          path: "/change_pin",
          builder: (_, _) => const ChangePinScreen(),
        ),
      ],
    );
    await settle(tester);
    return router;
  }

  Future<void> idle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> type(WidgetTester tester, String digits) async {
    for (final d in digits.split("")) {
      await tester.sendKeyEvent(
        LogicalKeyboardKey.findKeyByKeyId(
          LogicalKeyboardKey.digit0.keyId + int.parse(d),
        )!,
      );
      await tester.pump();
    }
    await idle(tester);
  }

  final enterOld = find.text("Enter your current PIN");
  final chooseShort = find.text("Choose a 5-digit PIN");
  final chooseLong = find.text("Choose a PIN");
  final confirm = find.text("Enter your new PIN again");

  testWidgets("a wrong old PIN: the enter page again, with the tries left", (
    tester,
  ) async {
    await pump(tester);
    expect(enterOld, findsOneWidget);
    await type(tester, "11111");
    expect(enterOld, findsOneWidget);
    expect(find.textContaining("2 tries left"), findsOneWidget);
  });

  testWidgets("out of tries: home, locked, the tokens dropped, the block "
      "given to the lock screen", (tester) async {
    left = 1;
    final router = await pump(tester);
    final blocks = <DateTime?>[];
    final sub = repo.appLock.blockedUntil.listen(blocks.add);
    addTearDown(sub.cancel);
    await type(tester, "11111");
    expect(currentLocation(router), "/home");
    expect(await repo.appLock.locked.first, isTrue);
    expect(
      bridge.dispatched.where(
        (e) => e.runtimeType.toString() == "DeleteKeyshareTokensEvent",
      ),
      isNotEmpty,
    );
    expect(blocks.whereType<DateTime>(), isNotEmpty);
  });

  testWidgets("the right old PIN: choose; the longer PIN is one tap away", (
    tester,
  ) async {
    await pump(tester);
    await type(tester, right);
    expect(chooseShort, findsOneWidget);
    await tester.tap(find.text("Prefer a longer PIN?"));
    await idle(tester);
    expect(chooseLong, findsOneWidget);
  });

  testWidgets("a mismatch: the dialog, then choose again, empty, as short as "
      "before", (tester) async {
    await pump(tester);
    await type(tester, right);
    await type(tester, "58193");
    expect(confirm, findsOneWidget);
    await type(tester, "58194");
    expect(find.text("PIN entered incorrectly"), findsOneWidget);
    await tester.tap(find.text("OK"));
    await idle(tester);
    expect(chooseShort, findsOneWidget);
    expect(find.bySemanticsLabel("No pin code entered"), findsOneWidget);
  });

  testWidgets("a match, then Change: the new PIN is sent, the toast, on "
      "Settings", (tester) async {
    final router = await pump(tester);
    await type(tester, right);
    await type(tester, "58193");
    await type(tester, "58193");
    expect(find.text("Are you sure?"), findsOneWidget);
    await tester.tap(find.text("Change"));
    await idle(tester);
    final sent = bridge.dispatched.whereType<ChangePinEvent>().single;
    expect((sent.oldPin, sent.newPin), (right, "58193"));
    expect(currentLocation(router), "/home/settings");
    expect(find.text("Success! Your new PIN has been saved"), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets("the dialog's Cancel: on Settings, nothing sent", (tester) async {
    final router = await pump(tester);
    await type(tester, right);
    await type(tester, "58193");
    await type(tester, "58193");
    await tester.tap(find.text("Cancel"));
    await idle(tester);
    expect(bridge.dispatched.whereType<ChangePinEvent>(), isEmpty);
    expect(currentLocation(router), "/home/settings");
  });

  testWidgets("an error from the server: the error screen; its close goes "
      "back to choose", (tester) async {
    changeAnswer = ChangePinErrorEvent(
      schemeManagerID: "pbdf",
      error: SessionError(errorType: "transport", info: "offline"),
    );
    await pump(tester);
    await type(tester, right);
    await type(tester, "58193");
    await type(tester, "58193");
    await tester.tap(find.text("Change"));
    await idle(tester);
    // A transport error: the no-internet screen.
    expect(find.byKey(const ValueKey("no_internet_screen")), findsOneWidget);
    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await idle(tester);
    expect(chooseShort, findsOneWidget);
  });

  testWidgets("back: from enter and choose to Settings, from confirm to "
      "choose", (tester) async {
    var router = await pump(tester);
    await tester.tap(find.byKey(const Key("irma_app_bar_leading")).last);
    await idle(tester);
    expect(currentLocation(router), "/home/settings");

    router = await pump(tester);
    await type(tester, right);
    await type(tester, "58193");
    expect(confirm, findsOneWidget);
    await tester.tap(find.byKey(const Key("irma_app_bar_leading")).last);
    await idle(tester);
    expect(chooseShort, findsOneWidget);
    await tester.tap(find.byKey(const Key("irma_app_bar_leading")).last);
    await idle(tester);
    expect(currentLocation(router), "/home/settings");
  });

  testWidgets("closing an error on the old-PIN step goes back to it", (
    tester,
  ) async {
    bridge.respond = (event) => event is AuthenticateEvent
        ? AuthenticationErrorEvent(
            error: SessionError(errorType: "transport", info: "offline"),
          )
        : null;
    await pump(tester);
    await type(tester, right);
    expect(find.byKey(const ValueKey("no_internet_screen")), findsOneWidget);
    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await idle(tester);
    expect(find.byKey(const ValueKey("no_internet_screen")), findsNothing);
    expect(enterOld, findsOneWidget);
  });
}
