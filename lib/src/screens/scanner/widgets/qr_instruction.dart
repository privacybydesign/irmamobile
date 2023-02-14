import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../theme/theme.dart';

class QRInstruction extends StatelessWidget {
  // QR code found
  final bool found;

  // wrong QR code found
  final bool error;

  const QRInstruction({required this.found, required final this.error});

  @override
  Widget build(BuildContext context) {
    var screen = 'instruction';
    var color = IrmaTheme.of(context).themeData.colorScheme.secondary;

    if (error) {
      screen = 'error';
      color = IrmaTheme.of(context).error;
    } else if (found) {
      screen = 'success';
      color = IrmaTheme.of(context).success;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
            color: color,
            child: Column(
              children: <Widget>[
                Text(
                  FlutterI18n.translate(context, 'qr_scanner.$screen.title'),
                  style: Theme.of(context).textTheme.headline3?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                Text(
                  FlutterI18n.translate(context, 'qr_scanner.$screen.message'),
                  style: Theme.of(context).textTheme.bodyText2?.copyWith(
                        color: Colors.white,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
