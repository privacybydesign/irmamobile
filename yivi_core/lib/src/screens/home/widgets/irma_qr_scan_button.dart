import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../../package_name.dart";
import "../../../theme/theme.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/test_detection.dart";
import "../../../widgets/translated_text.dart";
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

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (sheetCtx) => SizedBox(
      height: MediaQuery.of(sheetCtx).size.height * 0.9,
      child: const ScannerScreen(),
    ),
  );
}

class IrmaQrScanButton extends StatelessWidget {
  const IrmaQrScanButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).size.height > 450 ? 52 : 42,
      ),
      constraints: const BoxConstraints(maxWidth: 90),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 72,
            width: 72,
            child: Stack(
              children: [
                Positioned.fill(
                  child: SvgPicture.asset(yiviAsset("ui/round-btn-bg.svg")),
                ),
                Positioned.fill(
                  child: ClipOval(
                    child: Material(
                      type: MaterialType.transparency,
                      child: Semantics(
                        button: true,
                        label: FlutterI18n.translate(
                          context,
                          "home.nav_bar.scan_qr",
                        ),
                        child: InkWell(
                          onTap: () => openQrCodeScanner(context),
                          child: Icon(
                            Icons.qr_code_scanner_rounded,
                            color: theme.onPrimary,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: theme.tinySpacing),
          ExcludeSemantics(
            child: TranslatedText(
              "home.nav_bar.scan_qr",
              textAlign: TextAlign.center,
              style: theme.themeData.textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}
