import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/scanner/widgets/qr_instruction.dart';
import 'package:irmamobile/src/screens/scanner/widgets/qr_overlay.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScanner extends StatefulWidget {
  final void Function() onClose;
  final void Function(String) onFound;

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
            constraints: BoxConstraints.expand(),
            child: CustomPaint(
              painter: QROverlay(found: found, error: error, theme: IrmaTheme.of(context)),
            ),
          ),
          QRInstruction(found: found, error: error),
        ],
      ),
    );
  }

  /// if valid code is found: return
  /// cancel the current error timer
  /// check whether code is valid
  /// -> on valid
  ///      set error = false
  ///      set found = true
  ///      cal onFound in 500 milliseconds
  /// -> on error
  ///      set error = true
  ///      set timer for 500 milliseconds -> after set error = false
  void _onQRViewCreated(QRViewController controller) {
    controller.scannedDataStream.listen((code) {
      if (_errorTimer != null && _errorTimer.isActive) {
        _errorTimer.cancel();
      }

      if (found) {
        return;
      }

      // TODO: validate code
      const isValid = false;

      if (isValid) {
        setState(() {
          found = true;
          error = false;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onFound(code);
        });
      } else {
        setState(() {
          error = true;
        });
        _errorTimer = Timer(const Duration(milliseconds: 500), () {
          setState(() {
            error = false;
          });
        });
      }
    });
  }
}
