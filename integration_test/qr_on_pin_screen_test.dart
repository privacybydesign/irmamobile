// tests for sessions initiated from the qr scanner button on the pin screen

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testIssuance(WidgetTester tester, Locale locale) async {
      await pumpIrmaApp(tester, irmaBinding.repository, locale);

      // should be on the pin screen, find the qr scanner button and press it
      final qrButton = find.byType(YiviAppBarQrCodeButton);
      await tester.tapAndSettle(qrButton);

      final attributes = createMunicipalityPersonalDataAttributes(locale);
      final session = await createIssuanceSession(attributes: attributes);

      // the scanner screen can't really do anything during an integration test
      // so we just pretend it scanned a QR code
      final ScannerScreenState scannerState = tester.state(find.byType(ScannerScreen));
      scannerState.onQrScanned(session);

      // wait for the transition to the pin screen is finished
      await tester.pumpAndSettle(Duration(milliseconds: 200));

      // enter the pin code (same as the one for unlocking)
      await unlock(tester);
    }

    testWidgets('issuance-en', (tester) => testIssuance(tester, Locale('en', 'EN')));
    testWidgets('issuance-nl', (tester) => testIssuance(tester, Locale('nl', 'NL')));
  });
}
