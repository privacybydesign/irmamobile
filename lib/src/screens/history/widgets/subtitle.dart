import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';

import 'log.dart';

class Subtitle extends StatelessWidget {
  final LogType logType;

  const Subtitle(this.logType);

  @override
  Widget build(BuildContext context) {
    return Text(
      _text(context),
      style: IrmaTheme.of(context).textTheme.display2,
    );
  }

  String _text(BuildContext context) {
    switch (logType) {
      case LogType.removal:
        return FlutterI18n.translate(context, "history.type.removal");
      case LogType.disclosing:
        return FlutterI18n.translate(context, "history.type.disclosing.subtitle");
      case LogType.issuing:
        return FlutterI18n.translate(context, "history.type.issuing.subtitle");
      case LogType.signing:
        return FlutterI18n.translate(context, "history.type.signing.subtitle");
    }
    return "";
  }
}
