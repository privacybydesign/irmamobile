import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRViewContainer extends StatefulWidget {
  final Function(String) onFound;

  const QRViewContainer({Key key, this.onFound}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewContainerState();
}

class _QRViewContainerState extends State<QRViewContainer> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

  QRViewController _qrViewController;
  StreamSubscription _qrViewSubscription;

  @override
  void dispose() {
    _qrViewSubscription?.cancel();
    _qrViewController?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    _qrViewController = controller;
    _qrViewSubscription = controller.scannedDataStream.listen((qr) => widget.onFound(qr));
  }

  @override
  Widget build(BuildContext context) => QRView(
        key: _qrKey,
        onQRViewCreated: _onQRViewCreated,
      );
}
