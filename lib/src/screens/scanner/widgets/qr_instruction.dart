import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';

class QRInstruction extends StatelessWidget {
  // QR code found
  final bool found;

  // wrong QR code found
  final bool error;

  final Orientation orientation;

  const QRInstruction({required this.found, required final this.error, required this.orientation});

  @override
  Widget build(BuildContext context) {
    var screen = 'instruction';
    var color = IrmaTheme.of(context).themeData.colorScheme.primary;

    if (error) {
      screen = 'error';
      color = IrmaTheme.of(context).overlayInvalid;
    } else if (found) {
      screen = 'success';
      color = IrmaTheme.of(context).overlayValid;
    }

    return Center(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(
                top: orientation == Orientation.portrait
                    ? IrmaTheme.of(context).hugeSpacing * 1.25
                    : IrmaTheme.of(context).smallSpacing),
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
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
