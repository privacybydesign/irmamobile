import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/scanner/widgets/qr_scanner.dart';

class ScannerScreen extends StatelessWidget {
  static const routeName = "/scanner";

  _onClose(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR code scan'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => _onClose(context),
        ),
      ),
      body: Stack(
        children: <Widget>[
          QRScanner(
            onClose: () => _onClose(context),
            onFound: (String code) {
              Future.delayed(Duration(seconds: 2), () {
                Navigator.of(context).pop();
              });
            },
          ),
        ],
      ),
    );
  }
}
