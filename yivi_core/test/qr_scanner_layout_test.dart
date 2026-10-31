import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/qr_scanner_factory_provider.dart";
import "package:yivi_core/src/screens/scanner/scanner_screen.dart";
import "package:yivi_core/src/screens/scanner/util/camera_access.dart";
import "package:yivi_core/src/screens/scanner/widgets/qr_scanner.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";

import "support/onboarding_v2_harness.dart";

/// A camera that shows a grey box; the test reads codes into it and says
/// whether it has a torch.
class _FakeCamera implements QrScannerFactory {
  void Function(String code)? read;
  ScannerTorch? torch;
  int toggles = 0;

  @override
  Widget build({
    required void Function(String code) onCodeFound,
    required ScannerTorch torch,
  }) {
    read = onCodeFound;
    this.torch = torch;
    torch.connect(() {
      toggles++;
      torch.report(available: true, on: !torch.on);
    });
    return const ColoredBox(key: Key("camera"), color: Color(0xFF2B2F34));
  }
}

class _FakePermission implements CameraPermission {
  CameraAccess access;

  /// What the user answers when asked.
  CameraAccess answer = CameraAccess.granted;
  int asked = 0;
  int settingsOpened = 0;

  _FakePermission(this.access);

  @override
  Future<CameraAccess> status() async => access;

  @override
  Future<CameraAccess> request() async {
    asked++;
    return access = answer;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

const _yiviCode =
    '{"u":"https://example.com/irma/session/abc","irmaqr":"disclosing"}';

void main() {
  group("the window", () {
    test("264 square; with the pill under it, in the middle", () {
      expect(
        QRScannerState.windowFor(const Size(390, 600)),
        const Rect.fromLTWH(63, 136, 264, 264),
      );
    });

    test("a short camera: smaller, and the pill still inside", () {
      final window = QRScannerState.windowFor(const Size(390, 260));
      expect(window.top, greaterThanOrEqualTo(16));
      expect(window.bottom + QRScannerState.pillRoom, lessThanOrEqualTo(260));
      expect(window.width, window.height);
    });
  });

  group("the sheet", () {
    late IrmaRepository repo;
    late _FakeCamera camera;

    setUp(() async {
      repo = IrmaRepository(
        client: RecordingBridge(),
        preferences: await freshPreferences(),
      );
      camera = _FakeCamera();
    });
    tearDown(() => repo.close());

    Future<void> pump(
      WidgetTester tester, {
      Size size = const Size(390, 782),
      required _FakePermission permission,
      void Function(Pointer)? onScanned,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      await pumpHome(
        tester,
        repo: repo,
        overrides: [
          qrScannerFactoryProvider.overrideWithValue(camera),
          cameraPermissionProvider.overrideWithValue(permission),
        ],
        home: LegacyMaterialBridge(child: ScannerScreen(onScanned: onScanned)),
      );
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets("upright: the bar on top, the instruction in a pill under "
        "the window, the torch in the middle under the camera", (tester) async {
      await pump(tester, permission: _FakePermission(CameraAccess.granted));
      camera.torch!.report(available: true);
      await tester.pump();
      final bar = tester.getRect(find.byKey(const Key("glass_sheet_title")));
      final cam = tester.getRect(find.byKey(const Key("camera")));
      final window = QRScannerState.windowFor(cam.size).shift(cam.topLeft);
      final pill = tester.getRect(find.byKey(const Key("qr_scanner_status")));
      final torch = tester.getRect(find.byKey(const Key("qr_scanner_torch")));
      expect(find.text("Scan QR code"), findsOneWidget);
      expect(cam.width, 390);
      expect(cam.top, greaterThan(bar.bottom));
      expect(pill.top, closeTo(window.bottom + 24, 0.5));
      expect(pill.bottom, lessThan(cam.bottom));
      expect(pill.center.dx, closeTo(195, 0.5));
      expect(torch.top, greaterThanOrEqualTo(cam.bottom));
      expect(torch.center.dx, closeTo(195, 0.5));
      expect(find.text("Point your camera at a Yivi QR code"), findsOneWidget);
      expect(find.byType(IrmaCloseButton), findsOneWidget);
    });

    testWidgets("sideways: the torch in a column at the left, the camera "
        "with the pill at the right", (tester) async {
      await pump(
        tester,
        size: const Size(750, 392),
        permission: _FakePermission(CameraAccess.granted),
      );
      // No torch: no column.
      expect(tester.getRect(find.byKey(const Key("camera"))).left, 0);

      camera.torch!.report(available: true);
      await tester.pump();
      final cam = tester.getRect(find.byKey(const Key("camera")));
      final pill = tester.getRect(find.byKey(const Key("qr_scanner_status")));
      final torch = tester.getRect(find.byKey(const Key("qr_scanner_torch")));
      expect(find.text("Scan QR code"), findsOneWidget);
      expect(cam.left, QRScannerState.sideColumn);
      expect(cam.right, 750);
      expect(pill.left, greaterThan(cam.left));
      expect(pill.bottom, lessThan(cam.bottom));
      expect(torch.right, lessThanOrEqualTo(QRScannerState.sideColumn));
      expect(find.byType(IrmaCloseButton), findsOneWidget);
    });

    testWidgets("the torch shows only with a torch, and switches", (
      tester,
    ) async {
      await pump(tester, permission: _FakePermission(CameraAccess.granted));
      expect(find.byKey(const Key("qr_scanner_torch")), findsNothing);

      camera.torch!.report(available: true);
      await tester.pump();
      expect(find.text("Flashlight"), findsOneWidget);

      await tester.tap(find.byKey(const Key("qr_scanner_torch")));
      await tester.pump();
      expect(camera.toggles, 1);
      expect(
        tester.getSemantics(find.byKey(const Key("qr_scanner_torch"))),
        matchesSemantics(
          label: "Flashlight",
          isButton: true,
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets("a Yivi code: green, then handed on", (tester) async {
      Pointer? scanned;
      await pump(
        tester,
        permission: _FakePermission(CameraAccess.granted),
        onScanned: (p) => scanned = p,
      );
      camera.read!(_yiviCode);
      await tester.pump();
      expect(find.text("Done, the QR code is scanned"), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      expect(scanned, isA<SessionPointer>());
    });

    testWidgets("another code: red for two seconds, then scanning again", (
      tester,
    ) async {
      await pump(tester, permission: _FakePermission(CameraAccess.granted));
      camera.read!("https://example.com/parking");
      await tester.pump();
      expect(find.text("This is not a Yivi QR code"), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pumpAndSettle();
      expect(find.text("Point your camera at a Yivi QR code"), findsOneWidget);
    });

    testWidgets("not asked yet: asks over the sheet, then the camera", (
      tester,
    ) async {
      final permission = _FakePermission(CameraAccess.askable);
      await pump(tester, permission: permission);
      expect(permission.asked, 1);
      expect(find.byKey(const Key("camera")), findsOneWidget);
    });

    testWidgets("refused: the sheet says so, with the way to Settings and "
        "the close button, and looks again on return", (tester) async {
      final permission = _FakePermission(CameraAccess.denied);
      await pump(tester, permission: permission);
      expect(permission.asked, 0);
      expect(find.byKey(const Key("camera")), findsNothing);
      expect(find.text("No access to your camera"), findsOneWidget);
      expect(find.byType(IrmaCloseButton), findsOneWidget);

      await tester.tap(find.byKey(const Key("qr_scanner_open_settings")));
      await tester.pump();
      expect(permission.settingsOpened, 1);

      // Access given in Settings; the app comes back.
      permission.access = CameraAccess.granted;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key("camera")), findsOneWidget);
    });

    testWidgets("refused sideways: the explanation beside the picture", (
      tester,
    ) async {
      await pump(
        tester,
        size: const Size(750, 392),
        permission: _FakePermission(CameraAccess.denied),
      );
      expect(find.text("No access to your camera"), findsOneWidget);
      expect(find.byType(IrmaCloseButton), findsOneWidget);
    });
  });
}
