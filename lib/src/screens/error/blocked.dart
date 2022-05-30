import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';

class Blocked extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Center(
            child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.block, color: IrmaTheme.of(context).warningRed, size: 100),
        Padding(
            padding: EdgeInsets.all(IrmaTheme.of(context).mediumSpacing),
            child: Column(children: <Widget>[
              Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    FlutterI18n.translate(context, "error.title"),
                    style: IrmaTheme.of(context).textTheme.headline1,
                    textAlign: TextAlign.center,
                  )),
              Text(
                FlutterI18n.translate(context, "error.types.blocked"),
                style: IrmaTheme.of(context).textTheme.bodyText2,
                textAlign: TextAlign.center,
              ),
            ])),
      ],
    )));
  }
}
