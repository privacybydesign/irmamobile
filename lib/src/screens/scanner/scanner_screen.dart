import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/session.dart';
import '../../util/handle_pointer.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';
import 'widgets/qr_scanner.dart';

class ScannerScreen extends StatefulWidget {
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final GlobalKey<QRScannerState> _qrKey = GlobalKey();

  void _onSuccess(BuildContext context, Pointer pointer) async {
    // QR was scanned using IRMA app's internal QR code scanner, so we know for sure
    // the session continues on a second device. Therefore we can overrule the session pointer.
    if (pointer is SessionPointer) {
      pointer.continueOnSecondDevice = true;
    }

    HapticFeedback.vibrate();

    // if the app is locked, we should first go to a pin screen
    // to unlock it
    if (await IrmaRepositoryProvider.of(context).getLocked().first) {
      if (!context.mounted) {
        return;
      }
      final bool? result = await context.push('/modal_pin');
      if (result == null || !result) {
        // auth failed... show error and return..
        _asyncResetQrScanner();
        return;
      }
    }

    if (!context.mounted) {
      return;
    }
    await handlePointer(context, pointer, pushReplacement: true);
    _asyncResetQrScanner();
  }

  _asyncResetQrScanner() {
    Future.delayed(Duration(milliseconds: 100), _qrKey.currentState?.reset);
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: isLandscape
          ? null
          : const IrmaAppBar(
              titleTranslationKey: 'qr_scanner.title',
            ),
      body: QRScanner(
        key: _qrKey,
        onFound: (code) => _onSuccess(context, code),
      ),
    );
  }
}
