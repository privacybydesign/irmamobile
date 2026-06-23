import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:yivi_core/src/models/enrollment_status.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/enrollment/enrollment_screen.dart";
import "package:yivi_core/src/widgets/yivi_themed_button.dart";

import "helpers/fake_local_auth.dart";
import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  final enableButton = find.byKey(const Key("biometric_enable"));
  final notNowButton = find.byKey(const Key("biometric_not_now"));
  final lockScreenBiometricButton = find.byKey(
    const Key("pin_biometric_button"),
  );
  final biometricToggle = find.byKey(const Key("biometric_toggle"));
  final emailScreen = find.byKey(const Key("email_input_field"));
  final homeTab = find.byType(DataTab).hitTestable();

  Future<bool> enabledPref() =>
      irmaBinding.repository.preferences.getBiometricEnabled().first;
  Future<bool> dismissedPref() =>
      irmaBinding.repository.preferences.getBiometricPromptDismissed().first;

  // ---------------------------------------------------------------------------
  // Enrollment opt-in (shown once, right after the PIN is confirmed).
  // ---------------------------------------------------------------------------
  group("biometric enrollment opt-in", () {
    setUp(
      () => irmaBinding.setUp(enrollmentStatus: EnrollmentStatus.unenrolled),
    );
    tearDown(() => irmaBinding.tearDown());

    final nextButton = find.byKey(const Key("enrollment_next_button"));

    // Walks introduction -> terms -> choose pin -> confirm pin, after which the
    // biometric dialog appears (a biometric is "available" via the fake).
    Future<void> walkToBiometricDialog(
      WidgetTester tester, {
      required bool authSucceeds,
    }) async {
      await pumpYiviApp(
        tester,
        irmaBinding.repository,
        localAuth: FakeLocalAuthentication(
          available: true,
          authenticateResult: authSucceeds,
        ),
      );
      expect(find.byType(EnrollmentScreen), findsOneWidget);

      // Introduction (3 steps)
      for (var i = 0; i < 3; i++) {
        await tester.tap(nextButton);
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Terms
      final checkbox = find.byKey(const Key("accept_terms_checkbox"));
      await tester.scrollUntilVisible(checkbox.hitTestable(), 50);
      await tester.tapAndSettle(checkbox);
      await tester.tapAndSettle(nextButton);

      // Choose + confirm PIN
      await enterPin(tester, "12345");
      await tester.tapAndSettle(find.text("Next"));
      await enterPin(tester, "12345");
    }

    testWidgets("enable persists the preference and advances to email", (
      tester,
    ) async {
      await walkToBiometricDialog(tester, authSucceeds: true);

      await tester.waitFor(enableButton);
      await tester.tapAndSettle(enableButton);

      // Wait for the flow to advance (dialog closed, prefs committed) before
      // asserting.
      await tester.waitFor(emailScreen);
      expect(await enabledPref(), true);
    });

    testWidgets("skip records a decline and advances to email", (tester) async {
      await walkToBiometricDialog(tester, authSucceeds: true);

      await tester.waitFor(notNowButton);
      await tester.tapAndSettle(notNowButton);

      await tester.waitFor(emailScreen);
      expect(await enabledPref(), false);
      expect(await dismissedPref(), true);
    });

    testWidgets("failed authentication leaves the prompt re-askable", (
      tester,
    ) async {
      await walkToBiometricDialog(tester, authSucceeds: false);

      await tester.waitFor(enableButton);
      await tester.tapAndSettle(enableButton);

      await tester.waitFor(emailScreen);
      // Not enabled, and not dismissed — so the post-unlock prompt can re-ask.
      expect(await enabledPref(), false);
      expect(await dismissedPref(), false);
    });
  });

  // ---------------------------------------------------------------------------
  // Enrolled-app surfaces: post-unlock prompt, lock-screen button, settings.
  // ---------------------------------------------------------------------------
  group("biometric (enrolled)", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("post-unlock prompt appears and enables", (tester) async {
      await pumpYiviApp(
        tester,
        irmaBinding.repository,
        localAuth: FakeLocalAuthentication(
          available: true,
          authenticateResult: true,
        ),
      );
      await enterPin(tester, "12345");

      await tester.waitFor(enableButton);
      await tester.tapAndSettle(enableButton);

      await tester.waitUntilDisappeared(enableButton);
      expect(await enabledPref(), true);
    });

    testWidgets("post-unlock prompt is suppressed once dismissed", (
      tester,
    ) async {
      await irmaBinding.repository.preferences.setBiometricPromptDismissed(
        true,
      );
      await pumpYiviApp(
        tester,
        irmaBinding.repository,
        localAuth: FakeLocalAuthentication(available: true),
      );
      await enterPin(tester, "12345");

      await tester.waitFor(homeTab);
      expect(enableButton, findsNothing);
    });

    testWidgets("lock-screen button unlocks the app", (tester) async {
      await irmaBinding.repository.preferences.setBiometricEnabled(true);
      await pumpYiviApp(
        tester,
        irmaBinding.repository,
        localAuth: FakeLocalAuthentication(
          available: true,
          authenticateResult: true,
        ),
      );

      await tester.waitFor(lockScreenBiometricButton);
      await tester.tapAndSettle(lockScreenBiometricButton);

      // Reached home without entering a PIN.
      await tester.waitFor(homeTab);
    });

    testWidgets("lock-screen button failure keeps the app locked", (
      tester,
    ) async {
      await irmaBinding.repository.preferences.setBiometricEnabled(true);
      await pumpYiviApp(
        tester,
        irmaBinding.repository,
        localAuth: FakeLocalAuthentication(
          available: true,
          authenticateResult: false,
        ),
      );

      await tester.waitFor(lockScreenBiometricButton);
      await tester.tapAndSettle(lockScreenBiometricButton);

      // Still on the PIN screen (number pad present), not home.
      expect(find.byKey(const Key("number_pad_key_1")), findsOneWidget);
      expect(homeTab, findsNothing);
    });

    testWidgets("biometric is unavailable while the PIN is blocked", (
      tester,
    ) async {
      await irmaBinding.repository.preferences.setBiometricEnabled(true);
      await pumpYiviApp(
        tester,
        irmaBinding.repository,
        localAuth: FakeLocalAuthentication(
          available: true,
          authenticateResult: true,
        ),
      );

      // Biometric is offered on the lock screen to begin with.
      await tester.waitFor(lockScreenBiometricButton);

      // Three wrong PINs trip the temporary block. Each wrong attempt shows a
      // dialog that we dismiss before the next one.
      final dialogFinder = find.byKey(const Key("irma_dialog"));
      for (var attempt = 0; attempt < 3; attempt++) {
        await enterPin(tester, "54321");
        await tester.waitFor(dialogFinder);
        await tester.tapAndSettle(
          find.descendant(
            of: dialogFinder,
            matching: find.byType(YiviThemedButton),
          ),
        );
      }

      // Blocked: the biometric button is gone (so it can't bypass the
      // lockout), and the app stays locked even though the fake would
      // authenticate successfully.
      expect(lockScreenBiometricButton, findsNothing);
      expect(find.byKey(const Key("number_pad_key_1")), findsOneWidget);
      expect(homeTab, findsNothing);
    });

    Future<void> navToSettings(
      WidgetTester tester, {
      required bool authSucceeds,
    }) async {
      // Suppress the post-unlock prompt so the unlock reaches home cleanly; the
      // toggle stays visible because biometric is still "available".
      await irmaBinding.repository.preferences.setBiometricPromptDismissed(
        true,
      );
      await pumpAndUnlockApp(
        tester,
        irmaBinding.repository,
        localAuth: FakeLocalAuthentication(
          available: true,
          authenticateResult: authSucceeds,
        ),
      );
      await tester.tapAndSettle(find.byKey(const Key("nav_button_more")));
      await tester.tapAndSettle(
        find.byKey(const Key("open_settings_screen_button")),
      );
      await tester.scrollUntilVisible(biometricToggle.hitTestable(), 50);
    }

    testWidgets("settings toggle enables then disables", (tester) async {
      await navToSettings(tester, authSucceeds: true);

      await tester.tapAndSettle(biometricToggle);
      expect(await enabledPref(), true);

      await tester.tapAndSettle(biometricToggle);
      expect(await enabledPref(), false);
    });

    testWidgets("settings toggle stays off when authentication fails", (
      tester,
    ) async {
      await navToSettings(tester, authSucceeds: false);

      await tester.tapAndSettle(biometricToggle);
      expect(await enabledPref(), false);
    });
  });
}
