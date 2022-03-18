import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/screens/scanner/widgets/qr_scanner.dart';
import 'package:irmamobile/src/util/handle_pointer.dart';

class ScannerScreen extends StatelessWidget {
  static const routeName = '/scanner';

  static void _onClose(BuildContext context) {
    Navigator.of(context).pop();
  }

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
        onClose: () => _onClose(context),
        onFound: (code) => _onSuccess(context, code),
      ),
    );
  }
}
