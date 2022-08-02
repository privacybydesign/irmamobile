import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/session.dart';
import '../../util/handle_pointer.dart';
import 'widgets/qr_scanner.dart';

class ScannerScreen extends StatelessWidget {
  static const routeName = '/scanner';

  void _onSuccess(BuildContext context, Pointer pointer) {
    // QR was scanned using IRMA app's internal QR code scanner, so we know for sure
    // the session continues on a second device. Therefore we can overrule the session pointer.
    if (pointer is SessionPointer) {
      pointer.continueOnSecondDevice = true;
    }

    HapticFeedback.vibrate();
    handlePointer(Navigator.of(context), pointer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QRScanner(
        onClose: () => Navigator.of(context).pop(),
        onFound: (code) => _onSuccess(context, code),
      ),
    );
  }
}
