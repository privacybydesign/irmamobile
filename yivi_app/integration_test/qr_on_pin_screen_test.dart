// tests for sessions initiated from the qr scanner button on the pin screen

import "dart:ui";

import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/pin/pin_screen.dart";
import "package:yivi_core/src/screens/pin/widgets/waiting_request_card.dart";
import "package:yivi_core/src/screens/scanner/lock_scanner_sheet.dart";
import "package:yivi_core/src/screens/scanner/scanner_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
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
      "unlock-page-says-who-en",
      (tester) => testUnlockPageSaysWho(tester, irmaBinding.repository),
    );
    testWidgets(
      "link-while-locked-shows-card-en",
      (tester) => testLinkWhileLockedShowsCard(tester, irmaBinding.repository),
    );
    testWidgets(
      "disclosure-goes-full-screen-en",
      (tester) => testDisclosureGoesFullScreen(tester, irmaBinding.repository),
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

// Scanning keeps the scanner sheet, on its next page: the PIN, with who the
// request is from. Closing the sheet asks first; stopping clears the
// pointer, reverting to normal unlock (QR button returns) without ever
// starting the session.
Future<void> testCancelPendingSession(
  WidgetTester tester,
  Locale locale,
  IrmaRepository repo,
) async {
  await pumpYiviApp(tester, repo, defaultLanguage: locale);
  await tapQrScannerButton(tester);
  await pretendToScanIssuanceQrCode(tester, locale);

  // The PIN page of the sheet; the lock screen under it hides its QR button.
  expect(find.byKey(const Key("lock_scanner_unlock")), findsOneWidget);
  expect(find.byType(YiviAppBarQrCodeButton), findsNothing);

  // Close the sheet and stop the request.
  await tester.tapAndSettle(
    find.descendant(
      of: find.byKey(const Key("lock_scanner_unlock")),
      matching: find.byType(IrmaCloseButton),
    ),
  );
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

  // The issuance goes on in the scanner sheet.
  await tester.waitFor(find.byKey(const Key("sheet_issue_add")).hitTestable());

  // Back declines it; the sheet closes on the home screen.
  await tester.tapAndSettle(
    find.bySemanticsLabel(RegExp("go back|terug", caseSensitive: false)).last,
  );
  await tester.waitFor(find.byType(DataTab).hitTestable());
  expect(find.byKey(const Key("sheet_issue_add")), findsNothing);
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

  // The issuance goes on in the scanner sheet: add, then Done.
  final add = find.byKey(const Key("sheet_issue_add"));
  await tester.waitFor(add.hitTestable());
  await tester.tapAndSettle(add);
  final done = find.byKey(const Key("sheet_done"));
  await tester.waitFor(done.hitTestable());
  await tester.tapAndSettle(done);

  // The sheet is gone, on the home screen.
  await tester.waitFor(find.byType(DataTab).hitTestable());
  expect(find.byType(LockScannerSheet), findsNothing);
}

// The PIN page of the scanner sheet says who the request is from and what
// they want, before the PIN. The staging issuer is not in the requestor
// scheme: its host, said plainly.
Future<void> testUnlockPageSaysWho(
  WidgetTester tester,
  IrmaRepository repo,
) async {
  await pumpYiviApp(tester, repo, defaultLanguage: Locale("en", "EN"));
  await tapQrScannerButton(tester);
  await pretendToScanIssuanceQrCode(tester, Locale("en", "EN"));

  final card = find.descendant(
    of: find.byKey(const Key("lock_scanner_unlock")),
    matching: find.byType(WaitingRequestCard),
  );
  await tester.waitFor(
    find.descendant(of: card, matching: find.text("is offering data")),
  );
  expect(find.text("Enter your PIN to see the request"), findsWidgets);
  expect(
    find.descendant(of: card, matching: find.textContaining("staging")),
    findsWidgets,
  );

  await unlock(tester);
  await tester.waitFor(find.byKey(const Key("sheet_issue_add")).hitTestable());
  await tester.tapAndSettle(find.bySemanticsLabel("Go back").last);
  await tester.waitFor(find.byType(DataTab).hitTestable());
}

// A disclosure scanned on the lock screen: the PIN in the sheet, then the
// request full screen.
Future<void> testDisclosureGoesFullScreen(
  WidgetTester tester,
  IrmaRepository repo,
) async {
  await pumpYiviApp(tester, repo, defaultLanguage: Locale("en", "EN"));
  await tapQrScannerButton(tester);

  final session = await createTestSession("""
    {
      "@context": "https://irma.app/ld/request/disclosure/v2",
      "disclose": [[["irma-demo.MijnOverheid.fullName.firstname"]]]
    }
  """);
  final ScannerScreenState scannerState = tester.state(
    find.byType(ScannerScreen),
  );
  scannerState.onQrScanned(session);
  await tester.pumpAndSettle(const Duration(seconds: 3));
  await tester.waitFor(find.text("is asking for data"));

  await unlock(tester);
  await tester.waitFor(find.byType(DisclosureShareScreen).hitTestable());
  expect(find.byType(LockScannerSheet), findsNothing);
}

Future<void> tapQrScannerButton(WidgetTester tester) async {
  // should be on the pin screen, find the qr scanner button and press it
  final qrButton = find.byType(YiviAppBarQrCodeButton);
  await tester.waitFor(qrButton);
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

// A link opened while the app is locked: the full-screen PIN says who the
// request is from and what they want, and the session opens full screen
// after the PIN.
Future<void> testLinkWhileLockedShowsCard(
  WidgetTester tester,
  IrmaRepository repo,
) async {
  await pumpYiviApp(tester, repo, defaultLanguage: Locale("en", "EN"));
  await tester.waitFor(find.byType(YiviAppBarQrCodeButton));

  final session = await createIssuanceSession(
    attributes: createMunicipalityPersonalDataAttributes(Locale("en", "EN")),
  );
  repo.setPendingPointer(session);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  final card = find.descendant(
    of: find.byType(PinScreen),
    matching: find.byType(WaitingRequestCard),
  );
  await tester.waitFor(
    find.descendant(of: card, matching: find.text("is offering data")),
  );
  expect(find.text("Enter your PIN to see the request"), findsOneWidget);
  expect(find.byType(LockScannerSheet), findsNothing);

  await unlock(tester);
  final decline = find.byKey(const Key("bottom_bar_secondary"));
  await tester.waitFor(decline.hitTestable());
  await tester.tapAndSettle(decline);
  await tester.waitFor(find.byType(DataTab).hitTestable());
}
