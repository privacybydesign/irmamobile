import "package:flutter/services.dart";
import "package:flutter/widgets.dart" show SizedBox;
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/authentication_events.dart";
import "package:yivi_core/src/screens/pin/pin_screen.dart";
import "package:yivi_core/src/screens/pin/providers/biometric_provider.dart";

import "support/onboarding_v2_harness.dart";

/// The lock screen's PIN with the real unlock notifier over a fake bridge,
/// as it is today. The lock scanner sheet's unlock page does the same with
/// its own reset; it sits behind the camera, so the simulator test
/// qr_on_pin_screen_test covers it.
void main() {
  late RecordingBridge bridge;
  late IrmaRepository repo;

  setUp(() async {
    bridge = RecordingBridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
    await repo.preferences.longPin.set(false);
  });
  tearDown(() => repo.close());

  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
      overrides: [
        biometricAvailableProvider.overrideWith((ref) async => false),
      ],
      home: PinScreen(onAuthenticated: () {}, onForgotPin: () {}),
    );
    await tester.pump(const Duration(milliseconds: 500));
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
  }

  Future<void> answered(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets("a wrong PIN clears the pad and says how many tries are left", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    bridge.respond = (event) => event is AuthenticateEvent
        ? AuthenticationFailedEvent(remainingAttempts: 2, blockedDuration: 0)
        : null;
    await pump(tester);
    await type(tester, "12345");
    await answered(tester);
    expect(find.bySemanticsLabel("No pin code entered"), findsOneWidget);
    expect(find.textContaining("2 tries left"), findsOneWidget);
    handle.dispose();
  });

  testWidgets("a block turns the keypad off and shows when to try again", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    bridge.respond = (event) => event is AuthenticateEvent
        ? AuthenticationFailedEvent(remainingAttempts: 0, blockedDuration: 60)
        : null;
    await pump(tester);
    await type(tester, "12345");
    await answered(tester);
    expect(find.textContaining("Try again in"), findsOneWidget);
    await type(tester, "1");
    expect(find.bySemanticsLabel("No pin code entered"), findsOneWidget);
    handle.dispose();
    // The countdown's last second runs out after the screen is gone.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
