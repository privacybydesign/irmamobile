// When the lock screen offers biometric unlock and scans on its own, and the
// backstop that keeps a waiting request behind the PIN (ADR 0004).
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:local_auth/local_auth.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/native_events.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_events.dart";
import "package:yivi_core/src/models/session_user_interaction.dart";
import "package:yivi_core/src/screens/pin/pin_screen.dart";
import "package:yivi_core/src/screens/pin/providers/biometric_provider.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";

import "support/onboarding_v2_harness.dart";

class _FakeLocalAuth implements LocalAuthentication {
  _FakeLocalAuth({this.available = true});

  final bool available;
  int prompts = 0;

  /// Runs while the OS prompt is up.
  void Function()? onPrompt;

  @override
  Future<bool> isDeviceSupported() async => available;

  @override
  Future<bool> get canCheckBiometrics async => available;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async =>
      available ? const [BiometricType.face] : const [];

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<Object?> authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    prompts++;
    onPrompt?.call();
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SessionPointer _pointer() =>
    Pointer.fromString(
          '{"u":"https://example.com/irma/session/abc","irmaqr":"disclosing"}',
        )
        as SessionPointer;

final _biometricButton = find.byKey(const Key("pin_biometric_button"));

void main() {
  late RecordingBridge bridge;
  late IrmaRepository repo;
  late _FakeLocalAuth auth;

  setUp(() async {
    // The prompt holds the privacy screen back while it is up.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("privacy_screen"),
          (call) async => true,
        );
    bridge = RecordingBridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
    await repo.preferences.longPin.set(false);
    await repo.preferences.biometricEnabled.set(true);
    await repo.preferences.biometricImmediate.set(true);
    auth = _FakeLocalAuth();
  });
  tearDown(() async {
    await repo.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel("privacy_screen"), null);
  });

  Future<bool> locked() => repo.appLock.locked.first;

  /// The lock screen, after native acknowledged the launch ([resolved]).
  Future<void> pump(WidgetTester tester, {bool resolved = true}) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    if (resolved) bridge.deliver(AppReadyAckEvent());
    await pumpHome(
      tester,
      repo: repo,
      overrides: [localAuthProvider.overrideWithValue(auth)],
      home: PinScreen(onAuthenticated: () {}, onForgotPin: () {}),
    );
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Ends the test with no timer running: the block's countdown.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  group("11. biometric shows and scans only when", () {
    testWidgets("available, enabled, not blocked, nothing waiting and the "
        "launch resolved", (tester) async {
      await pump(tester);

      expect(_biometricButton, findsOneWidget);
      expect(auth.prompts, 1);
      await settle(tester);
      expect(await locked(), isFalse);
    });

    testWidgets("not when the device has none", (tester) async {
      auth = _FakeLocalAuth(available: false);
      await pump(tester);

      expect(_biometricButton, findsNothing);
      expect(auth.prompts, 0);
    });

    testWidgets("not when it is switched off", (tester) async {
      await repo.preferences.biometricEnabled.set(false);
      await pump(tester);

      expect(_biometricButton, findsNothing);
      expect(auth.prompts, 0);
    });

    testWidgets("shown but not scanned when scanning at once is off", (
      tester,
    ) async {
      await repo.preferences.biometricImmediate.set(false);
      await pump(tester);

      expect(_biometricButton, findsOneWidget);
      expect(auth.prompts, 0);
    });

    testWidgets("not while blocked after wrong PINs", (tester) async {
      repo.appLock.lock(
        unblockTime: DateTime.now().add(const Duration(minutes: 1)),
      );
      await pump(tester);

      expect(_biometricButton, findsNothing);
      // Not checked: the screen's first frame comes before the block is
      // known, and today the automatic scan already fires there.
      await unmount(tester);
    });

    testWidgets("not while a pointer is queued", (tester) async {
      repo.setPendingPointer(_pointer());
      await pump(tester);

      expect(_biometricButton, findsNothing);
      expect(auth.prompts, 0);
    });

    testWidgets("not while a session is in flight", (tester) async {
      repo.dispatch(NewSessionEvent(sessionId: 1, request: _pointer()));
      await pump(tester);

      expect(_biometricButton, findsNothing);
      expect(auth.prompts, 0);
    });

    testWidgets("not before the launch is resolved; then it scans", (
      tester,
    ) async {
      await pump(tester, resolved: false);

      expect(_biometricButton, findsNothing);
      expect(auth.prompts, 0);

      bridge.deliver(AppReadyAckEvent());
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 500));

      expect(auth.prompts, 1);
    });
  });

  testWidgets("12. a waiting request: no biometric, a close button that "
      "stops it", (tester) async {
    repo.dispatch(NewSessionEvent(sessionId: 1, request: _pointer()));
    await settle(tester);
    repo.setPendingPointer(_pointer());
    await pump(tester);

    expect(_biometricButton, findsNothing);
    expect(find.byType(IrmaCloseButton), findsOneWidget);

    await tester.tap(find.byType(IrmaCloseButton));
    await settle(tester);
    await tester.tap(find.byKey(const Key("dialog_confirm_button")));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(repo.pendingPointer, isNull);
    final dismissed = bridge.dispatched
        .whereType<SessionUserInteractionEvent>()
        .where((e) => e.type == UserInteractionType.dismiss)
        .map((e) => e.sessionId);
    expect(dismissed, [1]);
    expect(await locked(), isTrue);
  });

  group("13. the backstop: a prompt that succeeds while a request arrived "
      "leaves the app locked", () {
    testWidgets("a pointer queued during the prompt", (tester) async {
      auth.onPrompt = () => repo.setPendingPointer(_pointer());
      await pump(tester);

      expect(auth.prompts, 1);
      await settle(tester);
      expect(await locked(), isTrue);
    });

    testWidgets("a session started during the prompt", (tester) async {
      auth.onPrompt = () =>
          repo.dispatch(NewSessionEvent(sessionId: 1, request: _pointer()));
      await pump(tester);

      expect(auth.prompts, 1);
      await settle(tester);
      expect(await locked(), isTrue);
    });
  });

  testWidgets("14. no scan after a logout; going to the background re-arms "
      "it", (tester) async {
    repo.appLock.logOut();
    await pump(tester);

    expect(_biometricButton, findsOneWidget);
    expect(auth.prompts, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(auth.prompts, 1);
  });
}
