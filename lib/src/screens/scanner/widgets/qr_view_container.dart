import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

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
  Widget build(BuildContext context) =>
      // TODO: The mobile scanner package does not support landscape mode out of the box.(mobile_scanner: 1.0.0)
      // The creator seems to be working on it.
      // https://github.com/juliansteenbakker/mobile_scanner/discussions/17
      // When this is supported remove orientation checks.
      NativeDeviceOrientationReader(
        builder: (context) {
          final orientation = NativeDeviceOrientationReader.orientation(context);
          late int quarterTurns;
          switch (orientation) {
            case NativeDeviceOrientation.landscapeLeft:
              quarterTurns = 3;
              break;
            case NativeDeviceOrientation.portraitDown:
              quarterTurns = 2;
              break;
            case NativeDeviceOrientation.landscapeRight:
              quarterTurns = 1;
              break;
            case NativeDeviceOrientation.portraitUp:
            case NativeDeviceOrientation.unknown:
              quarterTurns = 0;
              break;
          }
          return RotatedBox(
            quarterTurns: quarterTurns,
            child: SizedBox(
              height: double.infinity,
              child: MobileScanner(
                  key: _qrKey,
                  controller: _controller,
                  onDetect: (barcode, args) {
                    if (barcode.rawValue != null) {
                      widget.onFound(barcode.rawValue!);
                    }
                  }),
            ),
          );
        },
      );
}
