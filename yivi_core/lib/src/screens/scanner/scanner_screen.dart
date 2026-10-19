import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../models/session.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../util/test_detection.dart";
import "../../widgets/glass/glass_surface.dart";
import "../../widgets/translated_text.dart";
import "widgets/qr_scanner.dart";

/// Modal-sheet QR scanner.
///
/// The default behavior on scan is to dismiss the sheet and queue the
/// scanned pointer on the repo — `PendingPointerListener` (mounted on
/// `/home`) picks it up and starts the session. The same flow covers
/// both the locked case (queued pointer waits behind the lock
/// overlay's PIN) and the unlocked case (fires immediately).
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => ScannerScreenState();
}

class ScannerScreenState extends State<ScannerScreen> {
  late final GlobalKey<QRScannerState> _qrKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isRunningIntegrationTest = TestContext.isRunningIntegrationTest(
      context,
    );
    if (!isRunningIntegrationTest) {
      try {
        _qrKey = GlobalKey(debugLabel: "qr_scanner_key");
      } catch (e) {
        // Do nothing, because _qrKey was already initialzed
      }
    }
  }

  void onQrScanned(Pointer pointer) {
    if (pointer is SessionPointer) {
      // QR was scanned using the in-app scanner, so the session
      // continues on a second device — overrule the pointer.
      pointer.continueOnSecondDevice = true;
    }

    HapticFeedback.vibrate();

    final repo = IrmaRepositoryProvider.of(context);
    Navigator.of(context).pop();
    repo.setPendingPointer(pointer);
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == .landscape;
    final palette = YiviPalette.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF23262A),
      // Expand: the title row is the only sized child, and without this the
      // stack (and with it the camera and the scan window) was only as tall
      // as that row.
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildBody(isLandscape)),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Semantics(
                        header: true,
                        child: TranslatedText(
                          "qr_scanner.title",
                          style: palette
                              .display(18)
                              .copyWith(
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x73000000),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GlassIconButton(
                          key: const Key("irma_app_bar_close"),
                          semanticsLabel: FlutterI18n.translate(
                            context,
                            "ui.close",
                          ),
                          dark: true,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool landscape) {
    // During integration tests we can't really scan QR codes,
    // so we'll just not render the whole scanner.
    // This will also prevent the permission dialog from being shown.
    if (TestContext.isRunningIntegrationTest(context)) {
      // when in landscape, the back button is rendered on the qr scanner widget
      // so we'll add a close button manually here, since the scanner is not
      // rendered in the tests and we still need a way to dismiss the sheet
      return Container();
    }

    return QRScanner(key: _qrKey, onFound: (code) => onQrScanned(code));
  }
}
