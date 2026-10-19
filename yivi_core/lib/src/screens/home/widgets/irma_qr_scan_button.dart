import "package:material_ui/material_ui.dart";

import "../../../util/adaptive_layout.dart";
import "../../../util/test_detection.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../scanner/scanner_screen.dart";
import "../../scanner/util/handle_camera_permission.dart";

/// Opens the QR scanner as a modal bottom sheet on whichever
/// Navigator owns [context]. The scanner dismisses itself on scan
/// and queues the pointer via the repo, so the same call site works
/// whether the app is locked (overlay's local Navigator owns the
/// sheet) or unlocked (GoRouter's main Navigator owns it).
Future<void> openQrCodeScanner(BuildContext context) async {
  // during tests we'll just pretend like we have permission, because it won't open the camera
  final isIntegrationTest = TestContext.isRunningIntegrationTest(context);
  final hasCameraPermission =
      isIntegrationTest || await handleCameraPermission(context);

  if (!hasCameraPermission || !context.mounted) return;

  // On tablets the scanner is a centred dialog instead of a sheet.
  if (isExpandedLayout(context)) {
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x8C000000),
      builder: (dialogCtx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
          child: ClipRSuperellipse(
            borderRadius: const BorderRadius.all(Radius.circular(38)),
            // The scanner lays itself out for the dialog, not the screen
            // (e.g. portrait in a landscape window).
            child: LayoutBuilder(
              builder: (context, constraints) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: constraints.biggest,
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                ),
                child: const ScannerScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // The app's one sheet; the scanner draws its own title and close button.
  await showGlassSheet<void>(
    context: context,
    heightFraction: 0.9,
    builder: (_) => const ScannerScreen(),
  );
}
