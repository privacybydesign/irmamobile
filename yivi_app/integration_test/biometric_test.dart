import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:yivi_core/src/models/enrollment_status.dart";
import "package:yivi_core/src/models/handle_url_event.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/enrollment/enrollment_screen.dart";
import "package:yivi_core/src/screens/pin/pin_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/widgets/yivi_themed_button.dart";

import "helpers/fake_local_auth.dart";
import "helpers/helpers.dart";
import "helpers/issuance_helpers.dart";
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
      // Disable auto-scan: this test drives the manual button.
      await irmaBinding.repository.preferences.setBiometricImmediate(false);
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
      // Disable auto-scan: this test drives the manual button.
      await irmaBinding.repository.preferences.setBiometricImmediate(false);
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

    // "Scan on launch" — auto-fires the biometric prompt when the lock screen
    // appears (immediate pref defaults on).
    testWidgets("immediate biometric auto-scans and unlocks on launch", (
      tester,
    ) async {
      await irmaBinding.repository.preferences.setBiometricEnabled(true);
      // immediate pref left at its default (on).
      await pumpYiviApp(
        tester,
        irmaBinding.repository,
        localAuth: FakeLocalAuthentication(
          available: true,
          authenticateResult: true,
        ),
      );

      // No tap: the auto-scan fires and reaches home on its own.
      await tester.waitFor(homeTab);
    });

    testWidgets("immediate biometric cancel falls back to PIN, fires once", (
      tester,
    ) async {
      await irmaBinding.repository.preferences.setBiometricEnabled(true);
      final fakeAuth = FakeLocalAuthentication(
        available: true,
        authenticateResult: false,
      );
      await pumpYiviApp(tester, irmaBinding.repository, localAuth: fakeAuth);

      // Auto-scan fired, failed, and we're back on the PIN pad with the manual
      // button still available — and it fired exactly once (no re-prompt loop).
      await tester.waitFor(lockScreenBiometricButton);
      expect(find.byKey(const Key("number_pad_key_1")), findsOneWidget);
      expect(homeTab, findsNothing);
      expect(fakeAuth.authenticateCalls, 1);
    });

    testWidgets("immediate off: no auto-scan, app stays locked", (
      tester,
    ) async {
      await irmaBinding.repository.preferences.setBiometricEnabled(true);
      await irmaBinding.repository.preferences.setBiometricImmediate(false);
      final fakeAuth = FakeLocalAuthentication(
        available: true,
        authenticateResult: true,
      );
      await pumpYiviApp(tester, irmaBinding.repository, localAuth: fakeAuth);

      // The button is offered but nothing auto-fires; the app stays locked.
      await tester.waitFor(lockScreenBiometricButton);
      expect(find.byKey(const Key("number_pad_key_1")), findsOneWidget);
      expect(homeTab, findsNothing);
      expect(fakeAuth.authenticateCalls, 0);
    });

    testWidgets("explicit logout suppresses the next auto-scan", (
      tester,
    ) async {
      await irmaBinding.repository.preferences.setBiometricEnabled(true);
      final fakeAuth = FakeLocalAuthentication(
        available: true,
        authenticateResult: true,
      );
      await pumpYiviApp(tester, irmaBinding.repository, localAuth: fakeAuth);

      // Auto-scan unlocks on launch (one authenticate call).
      await tester.waitFor(homeTab);
      expect(fakeAuth.authenticateCalls, 1);

      // Log out from the More tab.
      await tester.tapAndSettle(find.byKey(const Key("nav_button_more")));
      await tester.tapAndSettle(find.byKey(const Key("log_out_button")));

      // The lock screen returns but does NOT auto-scan: still locked, and no
      // second authenticate call. The manual button is still offered.
      await tester.waitFor(lockScreenBiometricButton);
      expect(find.byKey(const Key("number_pad_key_1")), findsOneWidget);
      expect(homeTab, findsNothing);
      expect(fakeAuth.authenticateCalls, 1);
    });

    testWidgets("re-opening after logout resumes the auto-scan", (
      tester,
    ) async {
      await irmaBinding.repository.preferences.setBiometricEnabled(true);
      final fakeAuth = FakeLocalAuthentication(
        available: true,
        authenticateResult: true,
      );
      await pumpYiviApp(tester, irmaBinding.repository, localAuth: fakeAuth);

      // Launch auto-scan unlocks (call 1).
      await tester.waitFor(homeTab);
      expect(fakeAuth.authenticateCalls, 1);

      // Log out — the lock screen returns but the scan is suppressed.
      await tester.tapAndSettle(find.byKey(const Key("nav_button_more")));
      await tester.tapAndSettle(find.byKey(const Key("log_out_button")));
      await tester.waitFor(lockScreenBiometricButton);
      expect(fakeAuth.authenticateCalls, 1);

      // Background then re-open: the logout suppression is dropped, so the scan
      // resumes and unlocks (call 2).
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.inactive,
      );
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pumpAndSettle();

      await tester.waitFor(homeTab);
      expect(fakeAuth.authenticateCalls, 2);
    });

    testWidgets("re-opening the app re-fires the auto-scan", (tester) async {
      await irmaBinding.repository.preferences.setBiometricEnabled(true);
      // authenticateResult:false keeps us on the lock screen, so a second scan
      // on re-open is observable via the call counter.
      final fakeAuth = FakeLocalAuthentication(
        available: true,
        authenticateResult: false,
      );
      await pumpYiviApp(tester, irmaBinding.repository, localAuth: fakeAuth);

      // Auto-scan fired once on launch and failed; still on the lock screen.
      await tester.waitFor(lockScreenBiometricButton);
      expect(fakeAuth.authenticateCalls, 1);

      // Let the launch scan fully unwind before backgrounding. `authenticateCalls`
      // ticks up inside `authenticate()`, but `_biometricUnlock` is still awaiting
      // (on iOS the privacy-screen disable/restore round-trips), so `_scanInProgress`
      // is still true here. The `paused` re-arm below only fires when a scan is NOT
      // in progress, so without settling first it would be skipped and the re-open
      // would never re-scan.
      await tester.pumpAndSettle();

      // Background then foreground the app.
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.inactive,
      );
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );

      // Re-open re-armed the guard, so the scan fires again. The counter ticks
      // up inside `authenticate()`, which on iOS sits behind an async
      // privacy-screen platform call that schedules no frame — pumpAndSettle
      // would return before it lands, so poll until the second scan arrives.
      await tester.pumpUntil(() => fakeAuth.authenticateCalls == 2);
      expect(fakeAuth.authenticateCalls, 2);
    });

    testWidgets("biometric is unavailable while the PIN is blocked", (
      tester,
    ) async {
      await irmaBinding.repository.preferences.setBiometricEnabled(true);
      // Disable auto-scan: a successful auto-scan would unlock before this test
      // can enter its wrong PINs.
      await irmaBinding.repository.preferences.setBiometricImmediate(false);
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

    // Regression for #644: the app must never unlock biometrically when it was
    // opened via a universal link carrying a session. A session has to be gated
    // behind a real PIN (only a PIN refreshes the keyshare token), so the
    // biometric auto-scan is held back until the launch URL is known. With a
    // session already queued at startup, biometric is never offered and never
    // auto-fires — the user is deterministically forced to the PIN, with no
    // "unlock then immediately re-lock" flash.
    testWidgets(
      "universal-link session at launch never unlocks biometrically",
      (tester) async {
        await irmaBinding.repository.preferences.setBiometricEnabled(true);
        // biometricImmediate left at its default (on): the auto-scan WOULD fire
        // on launch if it weren't gated by the pending session.
        final fakeAuth = FakeLocalAuthentication(
          available: true,
          authenticateResult: true,
        );

        // The session the universal link carries is already queued when the app
        // starts — the cold-start case the fix makes deterministic (the pointer
        // is delivered before biometric is allowed to run).
        await startIssuanceSession(
          irmaBinding,
          groupAttributes(
            createMunicipalityPersonalDataAttributes(const Locale("en", "EN")),
          ),
        );

        await pumpYiviApp(tester, irmaBinding.repository, localAuth: fakeAuth);
        await tester.pumpAndSettle();

        // Biometric never ran: no auto-scan, no button. Still on the PIN lock
        // screen — not home, and not advanced into the session.
        expect(fakeAuth.authenticateCalls, 0);
        expect(lockScreenBiometricButton, findsNothing);
        expect(find.byKey(const Key("number_pad_key_1")), findsOneWidget);
        expect(homeTab, findsNothing);
        expect(find.byType(SessionScreen), findsNothing);

        // Only a real PIN unlock lets the queued session proceed.
        await unlock(tester);
        await tester.waitFor(find.byType(IssuancePermission));
      },
    );

    // Regression for #654: a universal-link session opened on a warm resume-lock
    // must be PIN-gated, never admitted by biometric. The lock screen withholds
    // biometric while a session is pending OR in flight; the backstop refuses a
    // biometric unlock if either holds when the OS prompt returns.

    // Background past the idle threshold and resume, so the next frame auto-locks
    // and PinScreen builds.
    Future<void> backgroundPastIdleAndResume(
      WidgetTester tester,
      Duration threshold,
    ) async {
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.inactive,
      );
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.hidden,
      );
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      await Future<void>.delayed(threshold * 4);
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.hidden,
      );
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.inactive,
      );
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump();
    }

    // Backstop: even if biometric auto-fires on a plain resume-lock, a session
    // arriving while the OS prompt is up must not be admitted by that unlock.
    testWidgets("resume-lock: a link arriving mid-prompt is refused by the "
        "backstop", (tester) async {
      await irmaBinding.repository.preferences.setBiometricEnabled(true);
      final fakeAuth = FakeLocalAuthentication(
        available: true,
        authenticateResult: true,
      );
      const threshold = Duration(milliseconds: 50);

      await pumpYiviApp(
        tester,
        irmaBinding.repository,
        localAuth: fakeAuth,
        idleLockThreshold: threshold,
      );
      await tester.waitFor(homeTab);
      expect(fakeAuth.authenticateCalls, 1);

      final pointer = await createIssuanceSession(
        attributes: createMunicipalityPersonalDataAttributes(
          const Locale("en", "EN"),
        ),
      );

      // Hold the prompt open so we can inject the link while it is up.
      fakeAuth.authenticateGate = Completer<bool>();

      // Resume with no link yet: the idle-lock auto-fires biometric, which now
      // waits on the gate (the "sheet is up").
      await backgroundPastIdleAndResume(tester, threshold);
      await tester.pumpUntil(() => fakeAuth.authenticateCalls == 2);

      // The link lands while the prompt is still up, then the user authenticates.
      irmaBinding.repository.dispatch(
        HandleURLEvent(url: jsonEncode(pointer.toJson())),
      );
      fakeAuth.authenticateGate!.complete(true);
      await tester.pumpAndSettle();

      // Backstop: the successful auth does not dismiss a lock screen with a
      // session waiting. Still locked, still no session started.
      expect(find.byType(PinScreen), findsOneWidget);
      expect(lockScreenBiometricButton, findsNothing);
      expect(find.byType(SessionScreen), findsNothing);
      expect(homeTab, findsNothing);

      // The PIN admits the queued session.
      await unlock(tester);
      await tester.waitFor(find.byType(IssuancePermission));
    });

    // The core #654 scenario: the app was UNLOCKED when it went to the
    // background, so a link arriving then is consumed into a *session*
    // immediately (the pending pointer is cleared) — before the resume idle-lock
    // re-locks. The lock screen therefore builds with no pending pointer, and it
    // is the in-flight-session gate (not the pointer gate) that must withhold
    // biometric so the session stays PIN-gated.
    testWidgets("resume-lock: a session started while backgrounded is PIN-gated", (
      tester,
    ) async {
      await irmaBinding.repository.preferences.setBiometricEnabled(true);
      final fakeAuth = FakeLocalAuthentication(
        available: true,
        authenticateResult: true,
      );
      const threshold = Duration(milliseconds: 50);

      await pumpYiviApp(
        tester,
        irmaBinding.repository,
        localAuth: fakeAuth,
        idleLockThreshold: threshold,
      );
      await tester.waitFor(homeTab);
      expect(fakeAuth.authenticateCalls, 1);

      // Deliver the link while the app is still unlocked at home: it starts the
      // session immediately, clearing the pending pointer.
      final pointer = await createIssuanceSession(
        attributes: createMunicipalityPersonalDataAttributes(
          const Locale("en", "EN"),
        ),
      );
      irmaBinding.repository.dispatch(
        HandleURLEvent(url: jsonEncode(pointer.toJson())),
      );
      await tester.waitFor(find.byType(IssuancePermission));
      expect(fakeAuth.authenticateCalls, 1);

      // Now background past the idle threshold and resume: the idle-lock re-locks
      // over the running session (and clears the keyshare token).
      await backgroundPastIdleAndResume(tester, threshold);
      await tester.pumpAndSettle();

      // The in-flight-session gate withholds biometric (still one call, from
      // launch); the lock screen is up and only a PIN can admit the session.
      expect(fakeAuth.authenticateCalls, 1);
      expect(find.byType(PinScreen), findsOneWidget);
      expect(lockScreenBiometricButton, findsNothing);

      // The PIN admits the session that was already in flight.
      await unlock(tester);
      await tester.waitFor(find.byType(IssuancePermission));
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
