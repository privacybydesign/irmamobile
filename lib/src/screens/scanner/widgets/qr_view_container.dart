import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRViewContainer extends StatefulWidget {
  final Function(String) onFound;

  const QRViewContainer({Key? key, required this.onFound}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewContainerState();
}

class _QRViewContainerState extends State<QRViewContainer> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

  late QRViewController _qrViewController;
  late StreamSubscription _qrViewSubscription;

  @override
  void dispose() {
    _qrViewSubscription.cancel();
    // TODO: Test this in UX-2.0
    // Due to an issue in the qr code scanner library, the camera is not always
    // disabled properly on iOS. Therefore we pause it manually for now.
    // https://github.com/juliuscanute/qr_code_scanner/issues/137
    // TODO: Is this still necessary? (check CHANGELOG qr_code_scanner 0.0.14)
    // if (Platform.isIOS) {
    //   _qrViewController.pauseCamera();
    // }
    _qrViewController.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    _qrViewController = controller;
    _qrViewSubscription = controller.scannedDataStream.listen((qr) {
      if (qr.code != null) {
        widget.onFound(qr.code!);
      }
    });
  }

  @override
  Widget build(BuildContext context) => QRView(
        key: _qrKey,
        onQRViewCreated: _onQRViewCreated,
      );
}
