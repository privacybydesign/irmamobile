import 'package:flutter/cupertino.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRViewContainer extends StatefulWidget {
  final Function(String) onFound;

  const QRViewContainer({Key? key, required this.onFound}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewContainerState();
}

class _QRViewContainerState extends State<QRViewContainer> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  final _controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);

  @override
  Widget build(BuildContext context) => MobileScanner(
      key: _qrKey,
      controller: _controller,
      onDetect: (barcode, args) {
        if (barcode.rawValue != null) {
          widget.onFound(barcode.rawValue!);
        }
      });
}
