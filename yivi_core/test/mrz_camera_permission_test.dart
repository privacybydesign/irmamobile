import "package:camera/camera.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_flow.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_sheet_step.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/mrz_camera_feed.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/mrz_scanner.dart";
import "package:yivi_core/src/screens/scanner/util/camera_access.dart";
import "package:yivi_core/src/screens/session/issuance/issue_sheet_progress.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/sheet/sheet.dart";

import "helpers/test_translation_loader.dart";
import "support/pump_translated.dart";

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

class _StillFeed implements MrzCameraFeed {
  @override
  var running = false;

  @override
  Widget? preview() => running ? const SizedBox.expand() : null;

  @override
  double get aspectRatio => 16 / 9;

  @override
  int? imageRotation() => 0;

  @override
  Future<void> start(void Function(CameraImage image) onImage) async =>
      running = true;

  @override
  Future<void> stop() async => running = false;
}

/// The camera step of adding a document asks for the camera through the
/// scanner's seam: once where it may, the fallback when refused, and it
/// looks again when the app comes back from Settings.
void main() {
  late BuildContext home;

  Future<void> pump(WidgetTester tester, _FakePermission permission) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await pumpTranslated(
      tester,
      ProviderScope(
        overrides: [
          cameraPermissionProvider.overrideWithValue(permission),
          mrzCameraFeedProvider.overrideWithValue(_StillFeed.new),
        ],
        child: IrmaTheme(
          builder: (_) => MaterialApp(
            localizationsDelegates: [
              FlutterI18nDelegate(
                translationLoader: TestTranslationLoader(
                  basePath: "assets/locales",
                  forcedLocale: const Locale("en", "US"),
                ),
              ),
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: Builder(
              builder: (context) {
                home = context;
                return const Scaffold(body: Text("home"));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    showSheet<void>(
      context: home,
      builder: (_) => SheetPages(
        onBack: () {},
        pages: [
          DocumentSheetStep(
            key: const ValueKey("document"),
            type: DocumentType.passport,
            subject: const IssueSheetSubject.none(),
            onBack: () {},
          ),
        ],
      ),
    );
    await frames(tester);
    ProviderScope.containerOf(home)
        .read(documentFlowProvider(DocumentType.passport).notifier)
        .capture(hasCamera: true);
    // The step slides in; the look-up runs after its first frame.
    await tester.pump();
  }

  final fallback = find.text("No camera permissions");

  testWidgets("granted: the camera, without asking", (tester) async {
    final permission = _FakePermission(CameraAccess.granted);
    await pump(tester, permission);
    expect(fallback, findsNothing);
    await frames(tester);
    expect(permission.asked, 0);
    expect(find.byType(MrzScanner), findsOneWidget);
    expect(fallback, findsNothing);
  });

  testWidgets("not asked yet: asks once; yes shows the camera", (tester) async {
    final permission = _FakePermission(CameraAccess.askable);
    await pump(tester, permission);
    await frames(tester);
    expect(permission.asked, 1);
    expect(find.byType(MrzScanner), findsOneWidget);
  });

  testWidgets("not asked yet, then no: the fallback", (tester) async {
    final permission = _FakePermission(CameraAccess.askable)
      ..answer = CameraAccess.askable;
    await pump(tester, permission);
    await frames(tester);
    expect(permission.asked, 1);
    expect(find.byType(MrzScanner), findsNothing);
    expect(fallback, findsOneWidget);
  });

  testWidgets("refused: no question, the fallback; Settings keeps the "
      "camera step and it looks again on return", (tester) async {
    final permission = _FakePermission(CameraAccess.denied);
    await pump(tester, permission);
    await frames(tester);
    expect(permission.asked, 0);
    expect(fallback, findsOneWidget);

    await tester.tap(find.text("Open settings"));
    await frames(tester);
    expect(permission.settingsOpened, 1);
    expect(
      ProviderScope.containerOf(
        home,
      ).read(documentFlowProvider(DocumentType.passport)).top,
      isA<CaptureStep>(),
    );
    expect(fallback, findsOneWidget);

    // Access given in Settings; the app comes back.
    permission.access = CameraAccess.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await frames(tester);
    expect(find.byType(MrzScanner), findsOneWidget);
    expect(fallback, findsNothing);
  });
}

/// The document pictures loop: fixed frames instead of settling.
Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
