// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';

class QRInstruction extends StatelessWidget {
  // QR code found
  final bool found;

  // wrong QR code found
  final bool error;

  const QRInstruction({
    @required this.found,
    @required final this.error,
  });

  @override
  Widget build(BuildContext context) {
    var screen = 'instruction';
    var color = IrmaTheme.of(context).grayscale40;

    if (error) {
      screen = 'error';
      color = IrmaTheme.of(context).overlayInvalid;
    } else if (found) {
      screen = 'success';
      color = IrmaTheme.of(context).overlayValid;
    }

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.only(top: IrmaTheme.of(context).largeSpacing),
          padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
          color: color.withOpacity(0.8),
          child: Column(
            children: <Widget>[
              Text(
                FlutterI18n.translate(context, "qr_scanner.$screen.title"),
                style: Theme.of(context).textTheme.display2.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              Text(
                FlutterI18n.translate(context, "qr_scanner.$screen.message"),
                style: Theme.of(context).textTheme.body1.copyWith(
                      color: Colors.white,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
