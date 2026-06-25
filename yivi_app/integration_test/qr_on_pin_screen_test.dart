// tests for sessions initiated from the qr scanner button on the pin screen

import "dart:ui";

import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/pin/pin_screen.dart";
import "package:yivi_core/src/screens/scanner/scanner_screen.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";

import "helpers/helpers.dart";
import "helpers/issuance_helpers.dart";
import "irma_binding.dart";
import "util.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("issuance-from-pin-screen", () {
    setUp(() async => await irmaBinding.setUp());
    tearDown(() async => await irmaBinding.tearDown());

    testWidgets(
      "cancel-issuance-after-pin-en",
      (tester) => testCancelIssuanceAfterPinEntered(
        tester,
        Locale("en", "EN"),
        irmaBinding.repository,
      ),
    );
    testWidgets(
      "cancel-issuance-after-pin-nl",
      (tester) => testCancelIssuanceAfterPinEntered(
        tester,
        Locale("nl", "NL"),
        irmaBinding.repository,
      ),
    );

    testWidgets(
      "issuance-en",
      (tester) =>
          testIssuance(tester, Locale("en", "EN"), irmaBinding.repository),
    );
    testWidgets(
      "issuance-nl",
      (tester) =>
          testIssuance(tester, Locale("nl", "NL"), irmaBinding.repository),
    );

    testWidgets(
      "back-from-qr-en",
      (tester) => testBackFromQrScanner(
        tester,
        Locale("en", "EN"),
        irmaBinding.repository,
      ),
    );
    testWidgets(
      "back-from-qr-nl",
      (tester) => testBackFromQrScanner(
        tester,
        Locale("nl", "NL"),
        irmaBinding.repository,
      ),
    );

    testWidgets(
      "cancel-pending-session-en",
      (tester) => testCancelPendingSession(
        tester,
        Locale("en", "EN"),
        irmaBinding.repository,
      ),
    );
    testWidgets(
      "cancel-pending-session-nl",
      (tester) => testCancelPendingSession(
        tester,
        Locale("nl", "NL"),
        irmaBinding.repository,
      ),
    );
  });
}

// Scanning queues a pending pointer; the pin screen then shows a trailing ✕.
// Tapping it and confirming clears the pointer, reverting to normal unlock
// (QR button returns) without ever starting the session.
Future<void> testCancelPendingSession(
  WidgetTester tester,
  Locale locale,
  IrmaRepository repo,
) async {
  await pumpYiviApp(tester, repo, defaultLanguage: locale);
  await tapQrScannerButton(tester);
  await pretendToScanIssuanceQrCode(tester, locale);

  // Pending state: QR button hidden, cancel ✕ shown.
  expect(find.byType(YiviAppBarQrCodeButton), findsNothing);
  expect(find.byType(IrmaCloseButton), findsOneWidget);

  // Cancel and confirm the dialog.
  await tester.tapAndSettle(find.byType(IrmaCloseButton));
  await tester.tapAndSettle(find.byKey(const Key("dialog_confirm_button")));

  // Back to normal unlock: still on PinScreen, QR button back, ✕ gone.
  expect(find.byType(PinScreen), findsOneWidget);
  expect(find.byType(YiviAppBarQrCodeButton), findsOneWidget);
  expect(find.byType(IrmaCloseButton), findsNothing);

  // Leave the app unlocked so teardown is happy.
  await unlockAndWaitForHome(tester);
}

Future<void> testCancelIssuanceAfterPinEntered(
  WidgetTester tester,
  Locale locale,
  IrmaRepository repo,
) async {
  await pumpYiviApp(tester, repo, defaultLanguage: locale);
  await tapQrScannerButton(tester);

  await pretendToScanIssuanceQrCode(tester, locale);

  await unlock(tester);

  final buttonFinder = find.byKey(const Key("bottom_bar_secondary"));
  await tester.waitFor(buttonFinder.hitTestable());

  // press the cancel button
  await tester.tapAndSettle(buttonFinder);

  // With the lock-screen QR scanner now shown as a modal on
  // LockGate's local Navigator (rather than the `/scanner` route),
  // canceling the issuance no longer has a scanner page underneath
  // to fall back to — the user simply ends up on the home screen.
  await tester.waitFor(find.byType(DataTab).hitTestable());
}

Future<void> testBackFromQrScanner(
  WidgetTester tester,
  Locale locale,
  IrmaRepository repo,
) async {
  await pumpYiviApp(tester, repo, defaultLanguage: locale);
  await tapQrScannerButton(tester);

  // Scanner is now a bottom-sheet modal, not a `/scanner` route.
  final qrScreen = find.byType(ScannerScreen);
  expect(qrScreen, findsOneWidget);

  // Sheet has a close button in the top-right (not a back button).
  final closeButton = find.byKey(const Key("irma_app_bar_close"));
  await tester.tapAndSettle(closeButton);

  // After dismissing the sheet we're back on LockGate's PinScreen.
  final pinScreen = find.byType(PinScreen);
  expect(pinScreen, findsOneWidget);

  // need to unlock, otherwise the test will not be happy
  await unlockAndWaitForHome(tester);
}

Future<void> testIssuance(
  WidgetTester tester,
  Locale locale,
  IrmaRepository repo,
) async {
  await pumpYiviApp(tester, repo, defaultLanguage: locale);
  await tapQrScannerButton(tester);

  await pretendToScanIssuanceQrCode(tester, locale);

  await unlock(tester);

  final button = find.byKey(const Key("bottom_bar_primary"));
  await tester.waitFor(button.hitTestable());

  // tap "add data"
  await tester.tapAndSettle(button);

  // tap "done"
  await tester.tapAndSettle(find.byKey(const Key("ok_button")));

  // ensure we're at the home screen
  await tester.waitFor(find.byType(DataTab).hitTestable());
}

Future<void> tapQrScannerButton(WidgetTester tester) async {
  // should be on the pin screen, find the qr scanner button and press it
  final qrButton = find.byType(YiviAppBarQrCodeButton);
  await tester.tapAndSettle(qrButton);
}

Future<void> pretendToScanIssuanceQrCode(
  WidgetTester tester,
  Locale locale,
) async {
  final attributes = createMunicipalityPersonalDataAttributes(locale);
  final session = await createIssuanceSession(attributes: attributes);

  // the scanner screen can't really do anything during an integration test
  // so we just pretend it scanned a QR code
  final ScannerScreenState scannerState = tester.state(
    find.byType(ScannerScreen),
  );
  scannerState.onQrScanned(session);

  // wait for the pin screen to be visible
  await tester.pumpAndSettle(Duration(seconds: 3));
}
