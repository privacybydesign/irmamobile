// Verifies the idle-lock behavior introduced by IdleLockObserver:
// a paused → idle → resumed cycle (longer than the idle threshold)
// must lock the app. Locking now overlays `PinScreen` on top of the
// currently mounted route (`LockGate`); the route stays mounted and
// resumes when the user enters their PIN.

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/pin/pin_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/settings/settings_screen.dart";

import "helpers/helpers.dart";
import "helpers/issuance_helpers.dart";
import "irma_binding.dart";
import "util.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("idle-lock", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets(
      "paused → idle → resumed shows lock overlay over current route",
      (tester) =>
          testPausedIdleResumedShowsLockOverlay(tester, irmaBinding.repository),
    );

    testWidgets(
      "paused → resumed below threshold does not lock",
      (tester) => testPausedResumedBelowThresholdDoesNotLock(
        tester,
        irmaBinding.repository,
      ),
    );

    testWidgets(
      "in-progress session survives idle lock",
      (tester) =>
          testInProgressSessionPreservedAcrossIdleLock(tester, irmaBinding),
    );

    testWidgets(
      "session arriving during resume window survives auto-lock",
      (tester) =>
          testUniversalLinkDuringResumeSurvivesAutoLock(tester, irmaBinding),
    );
  });
}

Future<void> testPausedIdleResumedShowsLockOverlay(
  WidgetTester tester,
  IrmaRepository repo,
) async {
  const threshold = Duration(milliseconds: 50);
  await pumpAndUnlockApp(tester, repo, idleLockThreshold: threshold);

  // Navigate to a deep non-home route. With the overlay design the
  // route stays mounted across lock/unlock — the user emerges back
  // where they were, behind the PIN prompt.
  await tester.tapAndSettle(find.byKey(const Key("nav_button_more")));
  await tester.tapAndSettle(
    find.byKey(const Key("open_settings_screen_button")),
  );
  expect(find.byType(SettingsScreen), findsOneWidget);

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
  await tester.pumpAndSettle();

  // Lock overlay is up. The settings route is still in the tree
  // (covered by the overlay, not popped).
  expect(find.byType(PinScreen), findsOneWidget);

  // After unlock the overlay drops and the user is back on the
  // settings screen they left behind — same route, no nav reset.
  await unlock(tester);
  await tester.pumpAndSettle();
  expect(find.byType(PinScreen), findsNothing);
  expect(find.byType(SettingsScreen), findsOneWidget);
}

Future<void> testInProgressSessionPreservedAcrossIdleLock(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  const threshold = Duration(milliseconds: 50);
  await pumpAndUnlockApp(
    tester,
    irmaBinding.repository,
    idleLockThreshold: threshold,
  );

  // Start an issuance session and wait until the user is on
  // IssuancePermission. Then simulate walking away (lifecycle paused
  // for longer than the idle threshold).
  await startIssuanceSession(
    irmaBinding,
    groupAttributes(
      createMunicipalityPersonalDataAttributes(const Locale("en", "EN")),
    ),
  );
  await tester.waitFor(find.byType(IssuancePermission));

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
  await tester.pumpAndSettle();

  // Lock overlay is up. The session route stays mounted underneath —
  // no dispose, no dismiss to Go, no orphaned state.
  expect(find.byType(PinScreen), findsOneWidget);
  expect(find.byType(SessionScreen), findsOneWidget);

  // After unlock the overlay drops and the user is back on the
  // session, ready to finish what they started.
  await unlock(tester);
  await tester.pumpAndSettle();
  expect(find.byType(PinScreen), findsNothing);
  expect(find.byType(IssuancePermission), findsOneWidget);
}

/// When a universal link lands in the same resume window as the
/// auto-lock decision, the URL should be queued through the lock and
/// the session picked up after PIN unlock — not killed by the
/// redirect → dispose → dismiss cascade.
///
/// Distinct from [testInProgressSessionClearedAfterIdleLock]: there
/// the user had been on the session before walking away; here the URL
/// arrives fresh during resume.
Future<void> testUniversalLinkDuringResumeSurvivesAutoLock(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  const threshold = Duration(milliseconds: 50);
  await pumpAndUnlockApp(
    tester,
    irmaBinding.repository,
    idleLockThreshold: threshold,
  );

  // No session is in progress yet — user is sitting on the data tab.
  expect(find.byType(DataTab), findsOneWidget);

  // Drive the iOS lifecycle going to background and sleep past the
  // threshold so the upcoming resume will trigger an auto-lock.
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

  // Simulate the universal link landing in the same resume window:
  // the pending pointer is set just before the lifecycle resumes, the
  // same way native delivers a deep link to the bridge while the app
  // is coming back to the foreground.
  await startIssuanceSession(
    irmaBinding,
    groupAttributes(
      createMunicipalityPersonalDataAttributes(const Locale("en", "EN")),
    ),
  );

  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.hidden,
  );
  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.inactive,
  );
  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.resumed,
  );
  await tester.pumpAndSettle();

  // Auto-lock fired. User sees PIN.
  expect(find.byType(PinScreen), findsOneWidget);

  await unlock(tester);
  await tester.pumpAndSettle();

  // Desired behavior: the URL the user tapped is picked up after
  // unlock and the session UI appears.
  await tester.waitFor(
    find.byType(IssuancePermission),
    timeout: const Duration(seconds: 10),
  );
  expect(
    find.byType(IssuancePermission),
    findsOneWidget,
    reason:
        "universal-link-initiated session was lost across the auto-lock "
        "cascade; after PIN unlock the user should see the session "
        "they just tapped, not the data tab",
  );
}

Future<void> testPausedResumedBelowThresholdDoesNotLock(
  WidgetTester tester,
  IrmaRepository repo,
) async {
  // Use a comfortably large threshold so a fast paused → resumed bounce
  // (e.g. Apple Pay, momentary phone interruption) cannot exceed it.
  const threshold = Duration(seconds: 30);
  await pumpAndUnlockApp(tester, repo, idleLockThreshold: threshold);

  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.inactive,
  );
  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.hidden,
  );
  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.paused,
  );
  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.hidden,
  );
  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.inactive,
  );
  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.resumed,
  );
  await tester.pumpAndSettle();

  // Still unlocked: user remains on home (DataTab) without a PIN prompt.
  expect(find.byType(PinScreen), findsNothing);
  expect(find.byType(DataTab), findsOneWidget);
}
