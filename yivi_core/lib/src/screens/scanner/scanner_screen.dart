import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../../models/session.dart";
import "../../providers/irma_repository_provider.dart";
import "../../util/test_detection.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_icon_button.dart";
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

    return Scaffold(
      appBar: isLandscape
          ? null
          : IrmaAppBar(
              titleTranslationKey: "qr_scanner.title",
              // No leading — the sheet is dismissed via the close
              // button in the top-right, matching the bottom-sheet
              // convention.
              leading: null,
              actions: [
                IrmaIconButton(
                  key: const Key("irma_app_bar_close"),
                  icon: Icons.close,
                  semanticsLabelKey: "ui.close",
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
      body: _buildBody(isLandscape),
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
      if (landscape) {
        return IrmaIconButton(
          icon: Icons.close,
          onTap: () => Navigator.of(context).pop(),
        );
      }
      return Container();
    }

    return QRScanner(key: _qrKey, onFound: (code) => onQrScanned(code));
  }
}
