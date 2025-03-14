import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/session.dart';
import '../../util/handle_pointer.dart';
import '../../util/navigation.dart';
import '../../util/test_detection.dart';
import '../../widgets/irma_app_bar.dart';
import 'widgets/qr_scanner.dart';

class ScannerScreen extends StatefulWidget {
  final bool requireAuthBeforeSession;

  const ScannerScreen({super.key, required this.requireAuthBeforeSession});

  @override
  State<ScannerScreen> createState() => ScannerScreenState();
}

class ScannerScreenState extends State<ScannerScreen> {
  late final GlobalKey<QRScannerState> _qrKey;

  @override
  void initState() {
    super.initState();
    if (!isRunningIntegrationTest()) {
      _qrKey = GlobalKey(debugLabel: 'qr_scanner_key');
    }
  }

  void onQrScanned(Pointer pointer) async {
    // QR was scanned using IRMA app's internal QR code scanner, so we know for sure
    // the session continues on a second device. Therefore we can overrule the session pointer.
    if (pointer is SessionPointer) {
      pointer.continueOnSecondDevice = true;
    }

    HapticFeedback.vibrate();

    if (widget.requireAuthBeforeSession) {
      final bool? result = await context.pushModalPin();
      if (result == null || !result) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    // when the scanner is not the top route, we want to replace the top route instead of pushing
    // a new one, so when we swipe back we end up in the scanner again
    final pushReplacement = !context.isScannerTopRoute();
    await handlePointer(context, pointer, pushReplacement: pushReplacement);
  }

  _asyncResetQrScanner() {
    if (isRunningIntegrationTest()) {
      return;
    }
    Future.delayed(Duration(milliseconds: 100), _qrKey.currentState?.reset);
  }

  @override
  Widget build(BuildContext context) {
    // when we build the scanner and it's actually visible (top route)
    // we want to reset the state, so it doesn't stick to a success screen when
    // coming back from the pin screen
    // we shouldn't do this when the scanner is not the top route, because then it
    // would start scanning QR codes again in the background...
    if (context.isScannerTopRoute()) {
      _asyncResetQrScanner();
    }

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: isLandscape
          ? null
          : const IrmaAppBar(
              titleTranslationKey: 'qr_scanner.title',
            ),
      body: _buildBody(isLandscape),
    );
  }

  Widget _buildBody(bool landscape) {
    // During integration tests we can't really scan QR codes,
    // so we'll just not render the whole scanner.
    // This will also prevent the permission dialog from being shown
    if (isRunningIntegrationTest()) {
      // when in landscape, the back button is rendered on the qr scanner widget
      // so we'll add one manually here, since the scanner is not rendered in the tests
      // and we still need a back button
      if (landscape) {
        return YiviBackButton();
      }
      return Container();
    }

    return QRScanner(
      key: _qrKey,
      onFound: (code) => onQrScanned(code),
    );
  }
}
