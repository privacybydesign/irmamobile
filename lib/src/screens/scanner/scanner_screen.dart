import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/session.dart';
import '../../util/handle_pointer.dart';
import '../../widgets/irma_app_bar.dart';
import 'widgets/qr_scanner.dart';

class ScannerScreen extends StatefulWidget {
  final bool requireAuthBeforeSession;

  const ScannerScreen({super.key, required this.requireAuthBeforeSession});

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

    if (widget.requireAuthBeforeSession) {
      final bool? result = await context.push('/modal_pin');
      if (result == null || !result) {
        return;
      }
    }

    if (!context.mounted) {
      return;
    }

    final pushReplacement = GoRouter.of(context).state.uri.path != '/scanner';
    await handlePointer(context, pointer, pushReplacement: pushReplacement);
  }

  _asyncResetQrScanner() {
    Future.delayed(Duration(milliseconds: 100), _qrKey.currentState?.reset);
  }

  @override
  Widget build(BuildContext context) {
    // when we build the scanner and it's actually visible (top route)
    // we want to reset the state, so it doesn't stick to a success screen when
    // coming back from the pin screen
    // we shouldn't do this when the scanner is not the top route, because then it
    // would start scanning QR codes again in the background...
    final route = GoRouter.of(context).state.path!;
    if (route == '/scanner') {
      _asyncResetQrScanner();
    }

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
