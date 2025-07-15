import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QRViewContainer extends StatefulWidget {
  final Function(String) onFound;

  const QRViewContainer({super.key, required this.onFound});

  @override
  State<StatefulWidget> createState() => _QRViewContainerState();
}

class _QRViewContainerState extends State<QRViewContainer> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

  late StreamSubscription _qrViewSubscription;

  @override
  void dispose() {
    _qrViewSubscription.cancel();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    _qrViewSubscription = controller.scannedDataStream.listen((qr) => widget.onFound(qr.code!));
  }

  @override
  Widget build(BuildContext context) {
    return QRView(
      key: _qrKey,
      onQRViewCreated: _onQRViewCreated,
    );
  }
}
