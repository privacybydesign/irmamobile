import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "package:yivi_core/src/models/enrollment_status.dart";
import "package:yivi_core/src/screens/enrollment/biometric_setup/biometric_setup_screen.dart";
import "package:yivi_core/src/screens/enrollment/enrollment_screen.dart";
import "package:yivi_core/src/screens/enrollment/provide_email/provide_email_screen.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/settings/settings_screen.dart";
import "package:yivi_core/src/util/biometric_auth.dart";

import "helpers/fake_biometric_auth.dart";
import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  // Default to a fake that reports supported + successful authenticate. Each
  // test reconfigures the returned fake as needed.
  late FakeBiometricAuth fakeBiometric;

  setUp(() {
    fakeBiometric = FakeBiometricAuth.install();
  });
  tearDown(FakeBiometricAuth.clearOverride);

  // ===========================================================================
  // Repository / preferences (no UI)
  // ===========================================================================

  group("biometric-repository", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("unlockWithBiometrics flips locked state", (tester) async {
      final repo = irmaBinding.repository;
      repo.lock();
      expect(await repo.getLocked().first, true);

      repo.unlockWithBiometrics();

      expect(await repo.getLocked().first, false);
      expect(await repo.getBlockTime().first, isNull);
    });

    testWidgets("preference defaults to false on a fresh setup", (
      tester,
    ) async {
      final repo = irmaBinding.repository;
      expect(await repo.preferences.getBiometricUnlockEnabled().first, false);
      expect(repo.preferences.getBiometricUnlockEnabledSync(), false);
    });

    testWidgets("preference round-trips through set/get", (tester) async {
      final repo = irmaBinding.repository;
      await repo.preferences.setBiometricUnlockEnabled(true);
      expect(await repo.preferences.getBiometricUnlockEnabled().first, true);
      expect(repo.preferences.getBiometricUnlockEnabledSync(), true);

      await repo.preferences.setBiometricUnlockEnabled(false);
      expect(await repo.preferences.getBiometricUnlockEnabled().first, false);
    });
  });

  // ===========================================================================
  // Settings screen toggle
  // ===========================================================================

  group("biometric-settings", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    Future<void> openSettings(WidgetTester tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await tester.tapAndSettle(find.byKey(const Key("nav_button_more")));
      await tester.tapAndSettle(
        find.byKey(const Key("open_settings_screen_button")),
      );
      expect(find.byType(SettingsScreen), findsOneWidget);
    }

    CupertinoSwitch switchOf(Finder toggleFinder) {
      final inner = find.descendant(
        of: toggleFinder,
        matching: find.byType(CupertinoSwitch),
      );
      return inner.evaluate().single.widget as CupertinoSwitch;
    }

    testWidgets("toggle is hidden when device reports unsupported", (
      tester,
    ) async {
      fakeBiometric.supported = false;
      await openSettings(tester);
      expect(find.byKey(const Key("biometric_unlock_toggle")), findsNothing);
    });

    testWidgets("toggle visible and defaults off when supported", (
      tester,
    ) async {
      await openSettings(tester);
      final toggle = find.byKey(const Key("biometric_unlock_toggle"));
      await tester.scrollUntilVisible(toggle.hitTestable(), 50);
      expect(switchOf(toggle).value, false);
      expect(
        await irmaBinding.repository.preferences
            .getBiometricUnlockEnabled()
            .first,
        false,
      );
    });

    testWidgets("enabling toggle requires a successful biometric prompt", (
      tester,
    ) async {
      await openSettings(tester);
      final toggle = find.byKey(const Key("biometric_unlock_toggle"));
      await tester.scrollUntilVisible(toggle.hitTestable(), 50);

      expect(fakeBiometric.authenticateCalls, 0);
      await tester.tapAndSettle(toggle);

      expect(fakeBiometric.authenticateCalls, 1);
      expect(switchOf(toggle).value, true);
      expect(
        await irmaBinding.repository.preferences
            .getBiometricUnlockEnabled()
            .first,
        true,
      );
    });

    testWidgets("cancelled biometric prompt leaves the toggle off", (
      tester,
    ) async {
      fakeBiometric.nextResult = const BiometricAuthResult(
        success: false,
        cancelled: true,
      );
      await openSettings(tester);
      final toggle = find.byKey(const Key("biometric_unlock_toggle"));
      await tester.scrollUntilVisible(toggle.hitTestable(), 50);

      await tester.tapAndSettle(toggle);

      expect(fakeBiometric.authenticateCalls, 1);
      expect(switchOf(toggle).value, false);
      expect(
        await irmaBinding.repository.preferences
            .getBiometricUnlockEnabled()
            .first,
        false,
      );
    });

    testWidgets("disabling toggle does NOT prompt biometric", (tester) async {
      await irmaBinding.repository.preferences.setBiometricUnlockEnabled(true);
      await openSettings(tester);
      final toggle = find.byKey(const Key("biometric_unlock_toggle"));
      await tester.scrollUntilVisible(toggle.hitTestable(), 50);
      expect(switchOf(toggle).value, true);

      await tester.tapAndSettle(toggle);

      // canAuthenticate is consulted on screen mount; disabling itself must
      // not trigger another authenticate prompt.
      expect(fakeBiometric.authenticateCalls, 0);
      expect(switchOf(toggle).value, false);
      expect(
        await irmaBinding.repository.preferences
            .getBiometricUnlockEnabled()
            .first,
        false,
      );
    });

    testWidgets("preferences.clearAll resets biometric unlock to false", (
      tester,
    ) async {
      final repo = irmaBinding.repository;
      await repo.preferences.setBiometricUnlockEnabled(true);
      expect(await repo.preferences.getBiometricUnlockEnabled().first, true);

      await repo.preferences.clearAll();

      expect(await repo.preferences.getBiometricUnlockEnabled().first, false);
    });
  });

  // ===========================================================================
  // Enrollment biometric setup step
  // ===========================================================================

  group("biometric-enrollment", () {
    setUp(
      () => irmaBinding.setUp(enrollmentStatus: EnrollmentStatus.unenrolled),
    );
    tearDown(() => irmaBinding.tearDown());

    Future<void> goThroughPinConfirm(WidgetTester tester) async {
      await pumpYiviApp(tester, irmaBinding.repository);
      expect(find.byType(EnrollmentScreen), findsOneWidget);

      // Introduction (3 next presses).
      final nextButtonFinder = find.byKey(const Key("enrollment_next_button"));
      for (var i = 0; i < 3; i++) {
        await tester.tap(nextButtonFinder);
        await tester.pump(const Duration(milliseconds: 500));
      }
      // Accept terms.
      final checkBoxFinder = find.byKey(const Key("accept_terms_checkbox"));
      await tester.scrollUntilVisible(checkBoxFinder.hitTestable(), 50);
      await tester.tapAndSettle(checkBoxFinder);
      await tester.tapAndSettle(nextButtonFinder);

      // Choose + confirm PIN.
      const pin = "12345";
      await enterPin(tester, pin);
      await tester.tapAndSettle(find.text("Next"));
      await enterPin(tester, pin);
      await tester.pumpAndSettle();
    }

    testWidgets("setup screen appears after pin-confirm on supported device", (
      tester,
    ) async {
      await goThroughPinConfirm(tester);
      expect(find.byType(BiometricSetupScreen), findsOneWidget);
      // The provide-email screen has NOT been shown yet.
      expect(find.byType(ProvideEmailScreen), findsNothing);
      expect(
        await irmaBinding.repository.preferences
            .getBiometricUnlockEnabled()
            .first,
        false,
      );
    });

    testWidgets("skip leaves preference disabled and continues to email", (
      tester,
    ) async {
      await goThroughPinConfirm(tester);
      expect(find.byType(BiometricSetupScreen), findsOneWidget);

      // The secondary button is the skip action.
      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_secondary")));

      expect(find.byType(BiometricSetupScreen), findsNothing);
      expect(find.byType(ProvideEmailScreen), findsOneWidget);
      expect(
        await irmaBinding.repository.preferences
            .getBiometricUnlockEnabled()
            .first,
        false,
      );
      expect(fakeBiometric.authenticateCalls, 0);
    });

    testWidgets("enable + successful prompt sets the preference", (
      tester,
    ) async {
      await goThroughPinConfirm(tester);
      expect(find.byType(BiometricSetupScreen), findsOneWidget);

      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

      expect(fakeBiometric.authenticateCalls, 1);
      expect(find.byType(BiometricSetupScreen), findsNothing);
      expect(find.byType(ProvideEmailScreen), findsOneWidget);
      expect(
        await irmaBinding.repository.preferences
            .getBiometricUnlockEnabled()
            .first,
        true,
      );
    });

    testWidgets("enable + cancelled prompt keeps user on setup screen", (
      tester,
    ) async {
      fakeBiometric.nextResult = const BiometricAuthResult(
        success: false,
        cancelled: true,
      );
      await goThroughPinConfirm(tester);
      expect(find.byType(BiometricSetupScreen), findsOneWidget);

      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

      expect(fakeBiometric.authenticateCalls, 1);
      // The bloc only advances on success; the user remains on the biometric
      // setup screen so they can retry or skip.
      expect(find.byType(BiometricSetupScreen), findsOneWidget);
      expect(find.byType(ProvideEmailScreen), findsNothing);
      expect(
        await irmaBinding.repository.preferences
            .getBiometricUnlockEnabled()
            .first,
        false,
      );
    });

    testWidgets("unsupported device skips biometric setup entirely", (
      tester,
    ) async {
      fakeBiometric.supported = false;
      await goThroughPinConfirm(tester);

      expect(find.byType(BiometricSetupScreen), findsNothing);
      expect(find.byType(ProvideEmailScreen), findsOneWidget);
    });
  });

  // ===========================================================================
  // App-open /pin screen biometric bypass
  // ===========================================================================

  group("biometric-pin-screen", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("preference disabled: no biometric prompt on app open", (
      tester,
    ) async {
      // Default preference is false.
      await pumpYiviApp(tester, irmaBinding.repository);

      // Wait for the pin screen to be present.
      await tester.waitFor(find.byKey(const Key("pin_screen")));

      // Pin screen short-circuits before consulting the biometric APIs when
      // the preference is off — neither canAuthenticate nor authenticate fire.
      expect(fakeBiometric.authenticateCalls, 0);

      // Manual PIN entry still works.
      await unlockAndWaitForHome(tester);
    });

    testWidgets(
      "preference enabled: biometric prompt fires and unlocks without keyshare",
      (tester) async {
        final repo = irmaBinding.repository;
        await repo.preferences.setBiometricUnlockEnabled(true);
        // Force the app into the locked state so /pin is presented on pump.
        repo.lock();

        await pumpYiviApp(tester, repo);

        // Wait for the biometric path to settle (canAuthenticate -> authenticate
        // -> unlockWithBiometrics -> onAuthenticated -> home).
        await tester.waitFor(find.byType(HomeScreen));
        expect(fakeBiometric.authenticateCalls, 1);
        expect(await repo.getLocked().first, false);
      },
    );

    testWidgets("cancelled biometric falls back to the manual PIN keypad", (
      tester,
    ) async {
      final repo = irmaBinding.repository;
      await repo.preferences.setBiometricUnlockEnabled(true);
      repo.lock();
      fakeBiometric.nextResult = const BiometricAuthResult(
        success: false,
        cancelled: true,
      );

      await pumpYiviApp(tester, repo);
      await tester.waitFor(find.byKey(const Key("pin_screen")));
      await tester.pumpAndSettle();

      expect(fakeBiometric.authenticateCalls, 1);
      expect(await repo.getLocked().first, true);

      // Number pad is interactive; the fingerprint retry icon is visible.
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
      await unlockAndWaitForHome(tester);
    });

    testWidgets("tapping the fingerprint key retries the biometric prompt", (
      tester,
    ) async {
      final repo = irmaBinding.repository;
      await repo.preferences.setBiometricUnlockEnabled(true);
      repo.lock();
      // First attempt is cancelled, second succeeds.
      fakeBiometric.nextResult = const BiometricAuthResult(
        success: false,
        cancelled: true,
      );

      await pumpYiviApp(tester, repo);
      await tester.waitFor(find.byKey(const Key("pin_screen")));
      await tester.pumpAndSettle();
      expect(fakeBiometric.authenticateCalls, 1);

      // Tap the retry fingerprint key with a successful outcome this time.
      fakeBiometric.nextResult = const BiometricAuthResult(success: true);
      await tester.tapAndSettle(find.byIcon(Icons.fingerprint));

      await tester.waitFor(find.byType(HomeScreen));
      expect(fakeBiometric.authenticateCalls, 2);
      expect(await repo.getLocked().first, false);
    });
  });
}
