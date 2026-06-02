// Verifies the idle-lock behavior introduced by IdleLockObserver:
// a paused → idle → resumed cycle (longer than the idle threshold) must
// lock the app and reset the navigation stack to /home, so the user never
// returns to a stale screen left behind from before they walked away.

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
      "paused → idle → resumed locks and resets nav to home",
      (tester) => testPausedIdleResumedLocksAndResetsToHome(
        tester,
        irmaBinding.repository,
      ),
    );

    testWidgets(
      "paused → resumed below threshold does not lock",
      (tester) => testPausedResumedBelowThresholdDoesNotLock(
        tester,
        irmaBinding.repository,
      ),
    );

    testWidgets(
      "in-progress session is cleared after idle lock",
      (tester) =>
          testInProgressSessionClearedAfterIdleLock(tester, irmaBinding),
    );
  });
}

Future<void> testPausedIdleResumedLocksAndResetsToHome(
  WidgetTester tester,
  IrmaRepository repo,
) async {
  const threshold = Duration(milliseconds: 50);
  await pumpAndUnlockApp(tester, repo, idleLockThreshold: threshold);

  // Navigate to a deep non-home route so we can prove the stack is reset.
  await tester.tapAndSettle(find.byKey(const Key("nav_button_more")));
  await tester.tapAndSettle(
    find.byKey(const Key("open_settings_screen_button")),
  );
  expect(find.byType(SettingsScreen), findsOneWidget);

  // Drive the full iOS lifecycle sequence going to background, sleep past
  // the threshold, then drive the sequence coming back to foreground.
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

  // App must be locked; user sees PIN, not the settings screen.
  expect(find.byType(PinScreen), findsOneWidget);
  expect(find.byType(SettingsScreen), findsNothing);

  // After unlock the user lands on the data tab specifically (not on the
  // more tab they were on before locking, and not back on SettingsScreen).
  await unlock(tester);
  await tester.waitFor(find.byType(DataTab).hitTestable());
  expect(find.byType(SettingsScreen), findsNothing);
  expect(find.byType(PinScreen), findsNothing);
}

Future<void> testInProgressSessionClearedAfterIdleLock(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  const threshold = Duration(milliseconds: 50);
  await pumpAndUnlockApp(
    tester,
    irmaBinding.repository,
    idleLockThreshold: threshold,
  );

  // Start an issuance session and pause once the user is sitting on
  // IssuancePermission. We deliberately do NOT continue the session — this
  // simulates the user walking away mid-flow, which is the scenario that
  // produced the original "stale screen after hours" complaint.
  await startIssuanceSession(
    irmaBinding,
    groupAttributes(
      createMunicipalityPersonalDataAttributes(const Locale("en", "EN")),
    ),
  );
  await tester.waitFor(find.byType(IssuancePermission));
  expect(find.byType(IssuancePermission), findsOneWidget);

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

  // App must be locked: PIN screen on top, session UI already torn down.
  expect(find.byType(PinScreen), findsOneWidget);
  expect(find.byType(IssuancePermission), findsNothing);
  expect(find.byType(SessionScreen), findsNothing);

  // After unlock the user lands on the data tab, NOT back on the unfinished
  // session — this is the exact regression we are guarding against.
  await unlock(tester);
  await tester.waitFor(find.byType(DataTab).hitTestable());
  expect(find.byType(IssuancePermission), findsNothing);
  expect(find.byType(SessionScreen), findsNothing);
  expect(find.byType(PinScreen), findsNothing);
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
