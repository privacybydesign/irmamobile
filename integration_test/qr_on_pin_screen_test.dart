// tests for sessions initiated from the qr scanner button on the pin screen

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/data/data_tab.dart';
import 'package:irmamobile/src/screens/pin/pin_screen.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

import 'helpers/helpers.dart';
import 'helpers/issuance_helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('issuance-from-pin-screen', () {
    setUp(() async => await irmaBinding.setUp());
    tearDown(() async => await irmaBinding.tearDown());

    testWidgets(
      'cancel-issuance-after-pin-en',
      (tester) => testCancelIssuanceAfterPinEntered(tester, Locale('en', 'EN'), irmaBinding.repository),
    );
    testWidgets(
      'cancel-issuance-after-pin-nl',
      (tester) => testCancelIssuanceAfterPinEntered(tester, Locale('nl', 'NL'), irmaBinding.repository),
    );

    testWidgets('issuance-en', (tester) => testIssuance(tester, Locale('en', 'EN'), irmaBinding.repository));
    testWidgets('issuance-nl', (tester) => testIssuance(tester, Locale('nl', 'NL'), irmaBinding.repository));

    testWidgets(
      'back-from-qr-en',
      (tester) => testBackFromQrScanner(tester, Locale('en', 'EN'), irmaBinding.repository),
    );
    testWidgets(
      'back-from-qr-nl',
      (tester) => testBackFromQrScanner(tester, Locale('nl', 'NL'), irmaBinding.repository),
    );
  });
}

Future<void> testCancelIssuanceAfterPinEntered(WidgetTester tester, Locale locale, IrmaRepository repo) async {
  await pumpIrmaApp(tester, repo, locale);
  await tapQrScannerButton(tester);

  await pretendToScanIssuanceQrCode(tester, locale);

  await unlock(tester);

  final buttonFinder = find.byKey(const Key('bottom_bar_secondary'));
  await tester.waitFor(buttonFinder.hitTestable());

  // press the cancel button
  await tester.tapAndSettle(buttonFinder);

  // we expect to go back to the QR scanner
  expect(find.byType(ScannerScreen), findsOneWidget);

  // back to the pin screen
  final backButton = find.byType(YiviBackButton);
  await tester.tapAndSettle(backButton);

  // unlock and wait so the test doesn't fail after completing
  await unlockAndWaitForHome(tester);
}

Future<void> testBackFromQrScanner(WidgetTester tester, Locale locale, IrmaRepository repo) async {
  await pumpIrmaApp(tester, repo, locale);
  await tapQrScannerButton(tester);

  final qrScreen = find.byType(ScannerScreen);
  expect(qrScreen, findsOneWidget);

  final backButton = find.byType(YiviBackButton);
  await tester.tapAndSettle(backButton);

  final pinScreen = find.byType(PinScreen);
  expect(pinScreen, findsOneWidget);

  // need to unlock, otherwise the test will not be happy
  await unlockAndWaitForHome(tester);
}

Future<void> testIssuance(WidgetTester tester, Locale locale, IrmaRepository repo) async {
  await pumpIrmaApp(tester, repo, locale);
  await tapQrScannerButton(tester);

  await pretendToScanIssuanceQrCode(tester, locale);

  await unlock(tester);

  final button = find.byKey(const Key('bottom_bar_primary'));
  await tester.waitFor(button.hitTestable());

  // tap "add data"
  await tester.tapAndSettle(button);

  // tap "done"
  await tester.tapAndSettle(find.byKey(const Key('ok_button')));

  // ensure we're at the home screen
  await tester.waitFor(find.byType(DataTab).hitTestable());
}

Future<void> tapQrScannerButton(WidgetTester tester) async {
  // should be on the pin screen, find the qr scanner button and press it
  final qrButton = find.byType(YiviAppBarQrCodeButton);
  await tester.tapAndSettle(qrButton);
}

Future<void> pretendToScanIssuanceQrCode(WidgetTester tester, Locale locale) async {
  final attributes = createMunicipalityPersonalDataAttributes(locale);
  final session = await createIssuanceSession(attributes: attributes);

  // the scanner screen can't really do anything during an integration test
  // so we just pretend it scanned a QR code
  final ScannerScreenState scannerState = tester.state(find.byType(ScannerScreen));
  scannerState.onQrScanned(session);

  // wait for the pin screen to be visible
  await tester.pumpAndSettle(Duration(seconds: 3));
}
