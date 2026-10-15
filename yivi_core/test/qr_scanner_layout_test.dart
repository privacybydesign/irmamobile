import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/providers/qr_scanner_factory_provider.dart";
import "package:yivi_core/src/screens/scanner/scanner_screen.dart";
import "package:yivi_core/src/screens/scanner/widgets/qr_instruction.dart";
import "package:yivi_core/src/screens/scanner/widgets/qr_scanner.dart";
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";

import "support/onboarding_v2_harness.dart";

class _FakeCamera implements QrScannerFactory {
  @override
  Widget build({required void Function(String code) onCodeFound}) =>
      const ColoredBox(key: Key("camera"), color: Color(0xFF2B2F34));
}

void main() {
  test("the window sits where the design has it, and shrinks to fit", () {
    expect(
      QRScannerState.windowFor(const Size(390, 796)),
      const Rect.fromLTWH(45, 232, 300, 300),
    );
    // A landscape sheet: smaller and higher, still inside.
    final short = QRScannerState.windowFor(const Size(800, 360));
    expect(short.bottom, lessThanOrEqualTo(360 - 32 + 0.01));
    expect(short.width, short.height);
  });

  testWidgets("the scanner fills the sheet, not just the title row", (
    tester,
  ) async {
    final repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
    addTearDown(repo.close);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 796);
    addTearDown(tester.view.reset);

    await pumpHome(
      tester,
      repo: repo,
      overrides: [qrScannerFactoryProvider.overrideWithValue(_FakeCamera())],
      home: const LegacyMaterialBridge(child: ScannerScreen()),
    );
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 100));

    // The camera covers the whole sheet.
    expect(
      tester.getSize(find.byKey(const Key("camera"))),
      const Size(390, 796),
    );
    // The instruction card sits below the title, 84 from the top.
    final card = tester.getRect(find.byType(QRInstruction));
    expect(card.top, greaterThanOrEqualTo(84));
    expect(card.bottom, lessThan(232));
    expect(find.text("Start scanning"), findsOneWidget);
  });
}
