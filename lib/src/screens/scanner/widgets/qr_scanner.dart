import 'dart:async';

import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/screens/scanner/widgets/qr_instruction.dart';
import 'package:irmamobile/src/screens/scanner/widgets/qr_overlay.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScanner extends StatefulWidget {
  final void Function() onClose;
  final void Function(SessionPointer) onFound;

  const QRScanner({
    Key key,
    @required this.onClose,
    @required this.onFound,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool found = false;
  bool error = false;
  Timer _errorTimer;

  QRViewController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
          ),
          Container(
            constraints: const BoxConstraints.expand(),
            child: CustomPaint(
              painter: QROverlay(found: found, error: error, theme: IrmaTheme.of(context)),
            ),
          ),
          QRInstruction(found: found, error: error),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    controller.scannedDataStream.listen(foundQR);
  }

  void foundQR(String qr) {
    // If we already found a correct QR, cancel the current error message
    if (_errorTimer != null && _errorTimer.isActive) {
      _errorTimer.cancel();
    }

    // Don't continue if this screen has already been 'used'
    if (found) {
      return;
    }

    // Decode QR and determine if it's valid
    SessionPointer sessionPointer;
    try {
      sessionPointer = SessionPointer.fromString(qr);
    } catch (e) {
      // pass
    }

    // If invalid, show an error message for a certain time
    if (sessionPointer == null) {
      setState(() {
        error = true;
      });
      _errorTimer = Timer(const Duration(milliseconds: 2000), () {
        setState(() {
          error = false;
        });
      });
      return;
    }

    // Signal success after a small timeout
    setState(() {
      found = true;
      error = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onFound(sessionPointer);
    });
  }
}
